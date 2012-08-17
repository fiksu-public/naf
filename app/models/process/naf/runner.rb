module Process::Naf
  class Runner < ::Af::Application
    opt :wait_time_for_processes_to_terminate, :default => 120
    opt :num_processes, :default => 10

    def initialize
      super
      @check_schedules_period = 1.minute
      @runner_stale_period = 10.minutes
      @loop_sleep_time = 5
    end

    def work
      machine = ::Naf::Machine.current

      unless machine.present?
        logger.fatal "this machine is not configued correctly"
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

        if ::Naf::Machine.is_it_time_to_check_schedules?(@check_schedules_period)
          logger.debug "it's time"
          if ::Naf::ApplicationSchedule.try_lock_schedules
            logger.info "checking schedules"
            machine.mark_checked_schedule
            ::Naf::ApplicationSchedule.unlock_schedules

            # check scheduled tasks
            ::Naf::ApplicationSchedule.should_be_queued do |application_schedule|
              logger.info "schedule application: #{application_schedule.inspect}"
            end

            # check the runner machines
            ::Naf::Machine.enabled.each do |runner_to_check|
              if runner_to_check.runner_alive
                logger.info "runner alive #{runner_to_check.inspect}"
                runner_to_check.mark_alive
              else
                logger.warn "runner not alive #{runner_to_check.inspect}"
              end

              if runner_to_check.is_stale?(@runner_stale_period)
                logger.alarm "runner down #{runner_to_check.inspect}"
                runner_to_check.mark_machine_dead
              end
            end
          end
        end

        # clean up children that have exited

        if @children.length > 0
          begin
            pid, status = Process.waitpid2(-1, Process::WNOHANG)
            if pid.present?
              # XXX remove from children list -- mark as dead
              child_job = @children.delete(pid)
              if child_job.present?
                if status.exited?
                  child_job.reload
                  child_job.finished_at = Time.zone.now
                  child_job.exit_status = status.exitstatus
                  child_job.termination_signal = status.termsig
                  child_job.save!
                else
                  # XXX this can happen if the child is sigstopped
                end
              else
                # XXX ERROR no child for returned pid -- this can't happen
              end
            end
          rescue # XXX just incase a job control failure -- more code here
          end
        end

        # start new jobs
        while @children.length < @num_processes
          begin
            job = machine.fetch_next_job

            break unless job.present?

            job.started_on_machine_id = machine.id
            job.started_at = Time.zone.now

            pid = Process.fork do
              job.execute
              # should never get here
            end

            if pid
              @children[pid] = job
            else
              # failed to execute -- interesting
              job.failed_to_start = true
              job.finished_at = Time.zone.now
            end

            job.save!
          rescue # XXX rescue for various issues
          end
        end

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
  end
end
