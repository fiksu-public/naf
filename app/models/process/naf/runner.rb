module Process::Naf
  class Runner < ::Af::Application
    opt :wait_time_for_processes_to_terminate, :default => 120
    opt :check_schedules_period, :default => 1
    opt :runner_stale_period, :default => 10
    opt :loop_sleep_time, :default => 5

    def initialize
      super
    end

    def work
      machine = ::Naf::Machine.current

      unless machine.present?
        logger.fatal "this machine is not configued correctly, please update #{::Naf::Machine.table_name} with an entry for this machine ipaddress: #{::Naf::Machine.machine_ip_address}"
        logger.fatal "exiting..."
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

        if ::Naf::Machine.is_it_time_to_check_schedules?(@check_schedules_period.minute)
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

              if runner_to_check.is_stale?(@runner_stale_period.minute)
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
            # XXX remove from children list -- mark as dead
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

            # this (job.application_type) needs to be fetched so that
            # there is no db access in the child fork we could do an
            # include in the job code although that is squirly code
            # AND it means runner dependancies are in the job model

            job.application_type
            job.save!

            pid = Process.fork do
              job.execute
              # should never get here
              logger.error "failed to execute #{job.inspect}"
              Process.exit
            end
            # 

            @children[pid] = job
            job.pid = pid
            job.save!
            logger.info "job started : #{job.inspect}"
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

      schedules_what_need_queuin = ::Naf::ApplicationSchedule.where(:enabled => true).
        find_all do |schedule|
        ( not_finished_applications[schedule.application_id].nil? &&
          ( application_last_runs[schedule.application_id].nil? ||
            (Time.zone.now - application_last_runs[schedule.application_id].finished_at) > (schedule.run_interval * 60)))
      end

      return schedules_what_need_queuin
    end
  end
end
