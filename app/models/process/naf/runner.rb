module Process::Naf
  class Runner < ::Af::Application
    opt :wait_time_for_processes_to_terminate, "time between askign processes to terminate and sending kill signals", :argument_note => "SECONDS", :default => 120
    opt :check_schedules_period, "time between checking schedules", :argument_note => "MINUTES", :default => 1
    opt :schedule_fudge_scale, "amount of time to look back in schedule for run_start_minute schedules (scaled to --check-schedule-period)", :default => 5
    opt :runner_stale_period, "amount of time to consider a machine out of touch if it hasn't updated its machine entry", :argument_note => "MINUTES", :default => 10
    opt :loop_sleep_time, "runner main loop sleep time", :argument_note => "SECONDS", :default => 30
    opt :server_address, "set the machines server address (dangerous)", :type => :string, :default => ::Naf::Machine.machine_ip_address, :hidden => true

    def initialize
      super
      update_opts :log_configuration_files, :default => ["af.yml", "naf.yml", "nafrunner.yml", "#{af_name}.yml"]
      @last_machine_log_level = nil
      @job_creator = ::Logical::Naf::JobCreator.new
    end

    def work
      machine = ::Naf::Machine.find_by_server_address(@server_address)

      unless machine.present?
        logger.fatal "This machine is not configued correctly (ipaddress: #{@server_address})."
        logger.fatal "Please update #{::Naf::Machine.table_name} with an entry for this machine."
        logger.fatal "Exiting..."
        exit 1
      end

      if machine.try_lock_for_runner_use
        begin
          work_machine(machine)
        ensure
          machine.unlock_for_runner_use
        end
      else
        logger.fatal "There is already a runner running on this machine, exiting..."
        exit 1
      end
    end

    def work_machine(machine)
      machine.mark_alive
      machine.mark_up

      # make sure no processes are thought to be running on
      # this machine
      terminate_old_processes(machine)

      logger.info "working: #{machine}"

      @children = {}

      at_exit {
        ::Af::Application.singleton.emergency_teardown
      }

      while true
        machine = ::Naf::Machine.find_by_server_address(@server_address)
        if machine.nil?
          logger.warn "this machine is misconfigued, server address: #{@server_address}"
          break
        elsif !machine.enabled
          logger.warn "this machine is disabled #{machine}"
          break
        elsif machine.marked_down
          logger.warn "this machine is marked down #{machine}"
          break
        end

        machine.mark_alive

        if machine.log_level != @last_machine_log_level
          @last_machine_log_level = machine.log_level
          unless @last_machine_log_level.blank?
            parse_and_set_logger_levels(@last_machine_log_level)
          end
        end

        job_fetcher = ::Logical::Naf::JobFetcher.new(machine)

        if ::Naf::Machine.is_it_time_to_check_schedules?(@check_schedules_period.minutes)
          logger.debug "it's time to check schedules"
          if ::Naf::ApplicationSchedule.try_lock_schedules
            logger.info "checking schedules"
            machine.mark_checked_schedule
            ::Naf::ApplicationSchedule.unlock_schedules

            # check scheduled tasks
            should_be_queued.each do |application_schedule|
              logger.info "schedule application: #{application_schedule}"
              Range.new(0, application_schedule.application_run_group_limit || 1, true).each do
                @job_creator.queue_application_schedule(application_schedule)
              end
            end

            # check the runner machines
            ::Naf::Machine.enabled.up.each do |runner_to_check|
              if runner_to_check.is_stale?(@runner_stale_period.minutes)
                logger.alarm "runner is stale for #{@runner_stale_period} minutes, #{runner_to_check}"
                runner_to_check.mark_machine_down(machine)
              end
            end
          end
        end

        # clean up children that have exited

        logger.info "cleaning up dead children: #{@children.length}"
        while @children.length > 0
          begin
            pid, status = Process.waitpid2(-1, Process::WNOHANG)
            break if pid.nil?
            child_job = @children.delete(pid)
            if child_job.present?
              if status.exited? || status.signaled?
                child_job.reload
                logger.info "cleaning up dead child: #{child_job}"
                child_job.finished_at = Time.zone.now
                child_job.exit_status = status.exitstatus
                child_job.termination_signal = status.termsig
                child_job.save!
              else
                # this can happen if the child is sigstopped
                logger.warn "child waited for did not exit: #{child_job.inspect}, status: #{status.inspect}"
              end
            else
              # XXX ERROR no child for returned pid -- this can't happen
              logger.warn "child pid: #{pid}, status: #{status.inspect}, not managed by this runner"
            end
          rescue StandardError => e
            # XXX just incase a job control failure -- more code here
            logger.error "some failure during child clean up"
            logger.error e.message
            logger.error e.backtrace.join("\n")
          end
        end

        # start new jobs
        logger.info "starting new jobs, num children: #{@children.length}/#{machine.thread_pool_size}"
        while @children.length < machine.thread_pool_size
          begin
            job = job_fetcher.fetch_next_job

            unless job.present?
              logger.info "no more jobs to run"
              break
            end

            logger.info "starting new job : #{job}"

            job.started_on_machine_id = machine.id
            job.started_at = Time.zone.now
            job.save!

            pid = job.spawn
            if pid
              @children[pid] = job
              job.pid = pid
              job.failed_to_start = false
              logger.info "job started : #{job}"
            else
              # should never get here (well, hopefully)
              job.failed_to_start = true
              job.finished_at = Time.zone.now
              logger.error "failed to execute #{job}"
            end

            job.save!
          rescue StandardError => e
            # XXX rescue for various issues
            logger.error "failure during job start"
            logger.error e.message
            logger.error e.backtrace.join("\n")
          end
        end
        logger.info "done starting jobs"

        sleep(@loop_sleep_time)
      end

      logger.info "runner quitting"
    end

    # kill(0, pid) seems to fail during at_exit block
    # so this shoots from the hip
    def emergency_teardown
      return if @children.length == 0
      logger.warn "emergency teardown of #{@children.length} job(s)"
      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "TERM")
      end
      sleep(2)
      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "KILL")
        # force job down
        child.finished_at = Time.zone.now
        child.save!
      end
    end

    def terminate_old_processes(machine)
      # check if any processes are hanging around and ask them
      # politely if they will please terminate

      jobs = assigned_jobs(machine)
      if jobs.length == 0
        logger.detail "no jobs to remove"
        return 
      end
      logger.info "number of old jobs to sift through: #{jobs.length}"
      jobs.each do |job|
        logger.detail "job still around: #{job}"
        if job.request_to_terminate == false
          logger.warn "politely asking process: #{job.pid} to terminate itself"
          job.request_to_terminate = true
          job.save!
        end
      end

      # wait
      (1..@wait_time_for_processes_to_terminate).each do |i|
        num_assigned_jobs = assigned_jobs(machine).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/#{@wait_time_for_processes_to_terminate}: sleeping 1 second while we wait for #{num_assigned_jobs} assigned job(s) to terminate as requested"
        sleep(1)
      end

      # nudge them to terminate
      jobs = assigned_jobs(machine)
      if jobs.length == 0
        logger.debug_gross "assigned jobs have exited after asking to terminate nicely"
        return
      end
      jobs.each do |job|
        logger.warn "sending SIG_TERM to process: #{job}"
        send_signal_and_maybe_clean_up(job, "TERM")
      end

      # wait
      (1..5).each do |i|
        num_assigned_jobs = assigned_jobs(machine).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/5: sleeping 1 second while we wait for #{num_assigned_jobs} assigned job(s) to terminate from SIG_TERM"
        sleep(1)
      end

      # kill with fire
      assigned_jobs(machine).each do |job|
        logger.alarm "sending SIG_KILL to process: #{job}"
        send_signal_and_maybe_clean_up(job, "KILL")
        # job force job down
        job.finished_at = Time.zone.now
        job.save!
      end
    end

    def send_signal_and_maybe_clean_up(job, signal)
      if job.pid.nil?
        job.finished_at = Time.zone.now
        job.save!
        return false
      end

      begin
        retval = Process.kill(signal, job.pid)
        logger.detail "#{retval} = kill(#{signal}, #{job.pid})"
      rescue Errno::ESRCH
        logger.detail "ESRCH = kill(#{signal}, #{job.pid})"
        # job does not exist -- mark it finished
        job.finished_at = Time.zone.now
        job.save!
        return false
      end
      return true
    end

    def is_job_process_alive?(job)
      return send_signal_and_maybe_clean_up(job, 0)
    end

    def assigned_jobs(machine)
      return ::Naf::Job.assigned_jobs(machine).select do |job|
        is_job_process_alive?(job)
      end
    end

    def should_be_queued
      not_finished_applications = ::Naf::Job.recently_queued.
        not_finished.
        find_all{|job| job.application_id.present? }.
        index_by{|job| job.application_id }

      application_last_runs = ::Naf::Job.application_last_runs.
        index_by{|job| job.application_id }

      # find the run_interval based schedules that should be queued
      # select anything that isn't currently running and completed
      # running more than run_interval minutes ago
      relative_schedules_what_need_queuin = ::Naf::ApplicationSchedule.where(:enabled => true).relative_schedules.select do |schedule|
        ( not_finished_applications[schedule.application_id].nil? &&
          ( application_last_runs[schedule.application_id].nil? ||
            (Time.zone.now - application_last_runs[schedule.application_id].finished_at) > (schedule.run_interval.minutes)))
      end

      # find the run_start_minute based schedules
      # select anything that
      #  isn't currently running (or queued) AND
      #  hasn't run since run_start_time AND
      #  should have been run by now AND
      #  that should have run within fudge period AND

      exact_schedules_what_need_queuin = ::Naf::ApplicationSchedule.where(:enabled => true).exact_schedules.select do |schedule|
        ( not_finished_applications[schedule.application_id].nil? &&
          ( application_last_runs[schedule.application_id].nil? ||
            ((Time.zone.now.to_date + schedule.run_start_minute.minutes) >= application_last_runs[schedule.application_id].finished_at)) &&
          (Time.zone.now - (Time.zone.now.to_date + schedule.run_start_minute.minutes)) >= 0.seconds &&
          ((Time.zone.now - (Time.zone.now.to_date + schedule.run_start_minute.minutes)) <= (@check_schedules_period * @schedule_fudge_scale).minutes)
          )
      end

      return relative_schedules_what_need_queuin + exact_schedules_what_need_queuin
    end
  end
end
