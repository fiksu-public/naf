module Process::Naf
  class Runner < ::Af::Application
    opt :wait_time_for_processes_to_terminate, "time between askign processes to terminate and sending kill signals", :argument_note => "SECONDS", :default => 120
    opt :check_schedules_period, "time between checking schedules", :argument_note => "MINUTES", :default => 1
    opt :schedule_fudge_scale, "amount of time to look back in schedule for run_start_minute schedules (scaled to --check-schedule-period)", :default => 5
    opt :runner_stale_period, "amount of time to consider a machine out of touch if it hasn't updated its machine entry", :argument_note => "MINUTES", :default => 10
    opt :loop_sleep_time, "runner main loop sleep time", :argument_note => "SECONDS", :default => 30

    def initialize
      super
      update_opts :log_file, :default => "naf"
    end

    def work
      machine = ::Naf::Machine.local_machine

      unless machine.present?
        logger.fatal "This machine is not configued correctly (ipaddress: #{::Naf::Machine.machine_ip_address})."
        logger.fatal "Please update #{::Naf::Machine.table_name} with an entry for this machine."
        logger.fatal "Exiting..."
        exit
      end

      machine.mark_alive

      # make sure no processes are thought to be running on
      # this machine
      terminate_old_processes(machine)

      logger.info "working: #{machine.inspect}"

      @children = {}

      while true
        machine = ::Naf::Machine.current
        if machine.nil? || !machine.enabled
          logger.warn "this machine is down #{machine.inspect}"
          break
        end

        if ::Naf::Machine.is_it_time_to_check_schedules?(@check_schedules_period.minutes)
          logger.debug "it's time to check schedules"
          if ::Naf::ApplicationSchedule.try_lock_schedules
            logger.info "checking schedules"
            machine.mark_checked_schedule
            ::Naf::ApplicationSchedule.unlock_schedules

            # check scheduled tasks
            should_be_queued.each do |application_schedule|
              logger.info "schedule application: #{application_schedule.inspect}"
              ::Naf::Job.queue_application_schedule(application_schedule)
            end

            # check the runner machines
            ::Naf::Machine.enabled.each do |runner_to_check|
              if runner_to_check.runner_alive
                logger.info "runner alive #{runner_to_check.inspect}"
                runner_to_check.mark_alive
              else
                logger.warn "runner not alive #{runner_to_check.inspect}"
              end

              if runner_to_check.is_stale?(@runner_stale_period.minutes)
                logger.alarm "runner down #{runner_to_check.inspect}"
                runner_to_check.mark_machine_dead
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
              if status.exited?
                child_job.reload
                logger.info "cleaning up dead child: #{child_job.inspect}"
                child_job.finished_at = Time.zone.now
                child_job.exit_status = status.exitstatus
                child_job.termination_signal = status.termsig
                child_job.save!
              else
                # this can happen if the child is sigstopped
                logger.warn "child waited for did not exit: #{child.inspect}, status: #{status.inspect}"
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
            job = machine.fetch_next_job

            unless job.present?
              logger.info "no more jobs to run"
              break 
            end

            logger.info "starting new job : #{job.inspect}"

            job.started_on_machine_id = machine.id
            job.started_at = Time.zone.now
            job.save!

            pid = job.spawn
            if pid
              @children[pid] = job
              job.pid = pid
              job.failed_to_start = false
              logger.info "job started : #{job.inspect}"
            else
              # should never get here (well, hopefullly)
              job.failed_to_start = true
              job.finished_at = Time.zone.now
              logger.error "failed to execute #{job.inspect}"
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

    def terminate_old_processes(machine)
      # check if any processes are hanging around and ask them
      # politely if they will please terminate

      jobs = assigned_jobs(machine)
      return jobs.length == 0
      jobs.each do |job|
        if job.request_to_terminate == false
          logger.warn "politely asking process: pid=#{job.pid} to terminate itself"
          job.request_to_terminate = true
          job.save!
        end
      end

      # wait
      (1..@wait_time_for_processes_to_terminate).each do
        return if assigned_jobs(machine).length == 0
        sleep(1)
      end

      # nudge them to terminate
      jobs = assigned_jobs(machine)
      return jobs.length == 0
      jobs.each do |job|
        logger.warn "sending SIG_TERM to process: pid=#{job.pid}, command=#{job.command}"
        send_signal_and_maybe_clean_up(job, "TERM")
      end

      # wait
      (1..5).each do
        return if assigned_jobs(machine).length == 0
        sleep(1)
      end

      # kill with fire
      assigned_jobs(machine).each do |job|
        logger.warn "sending SIG_KILL to process: pid=#{job.pid}, command=#{job.command}"
        send_signal_and_maybe_clean_up(job, "KILL")
      end
    end

    def send_signal_and_maybe_clean_up(job, signal)
      if job.pid.nil?
        job.finished_at = Time.zone.now
        job.save!
        return false
      end

      begin
        Process.kill(signal, job.pid)
      rescue Errno::ESRCH
        # job does not exist -- mark it finished
        job.finished_at = Time.zone.now
        job.save!
        return false
      end
      return true
    end

    def assigned_jobs(machine)
      return machine.assigned_jobs.select do |job|
        send_signal_and_maybe_clean_up(job, 0)
      end.map(&:pid)
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
