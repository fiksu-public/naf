module Process::Naf
  class Runner < ::Af::Application
    include ::Af::QThread::Interface
    attr_reader :queue

    opt :ask_processes_to_terminate, :default => false
    opt :wait_time_for_processes_to_terminate, :default => 120

    def initialize
      super
      @thread_pool_size = 10
      @check_schedules_period = 1.minute
      @runner_stale_period = 10.minutes
      @loop_sleep_time = 5
      @queue = Queue.new
    end

    def work
      machine = ::Naf::Machine.current

      unless machine.present?
        logger.fatal "this machine is not configued correctly"
      end

      machine.mark_alive

      # make sure no processes are thought to be running on
      # this machine
      terminate_old_processes

      logger.info "working: #{machine.inspect}"

      pool = ::Af::ThreadPool.new(@thread_pool_size, ::Af::QThread::Base)

      (1..@thread_pool_size).each do |n|
        pool.process do
          begin
            Process::Naf::RunnerThreadMessageHandler.run
          rescue Exception => e
            logger.alarm e
          end
        end
      end

      logger.info "kick starting"
      pool.workers.each do |worker|
        worker.thread.kick_start(self)
      end

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

        while has_message?
          message = read_message
          logger.info "message from child: #{message.data}"
        end

        sleep(@loop_sleep_time)
      end

      logger.info "runner quitting"

      pool.workers.each do |worker|
        worker.thread.request_termination(self)
      end

      pool.join()
    end

    def terminate_old_processes
      assinged_jobs = ::Naf::Machine.assigned_jobs
      if assigned_jobs.length > 0
        if @ask_processes_to_terminate
          logger.warn "terminating old processes #{assigned_jobs.length}"
          assigned_jobs.each do |job|
            if job.finished_at.nil? && job.request_to_terminate == false
              logger.warn "politely asking process: pid=#{job.pid} to terminate itself"
              job.request_to_terminate = true
              job.save!
            end
          end
          logger.warn "waiting for processes to terminate"
          (1..@wait_time_for_processes_to_terminate).each do
            sleep(1)
            break if ::Naf::Machine.assigned_jobs.length == 0
          end
        end

        assinged_jobs = ::Naf::Machine.assigned_jobs
        if assigned_jobs.length > 0
          logger.warn "terminating processes manually (SIG_TERM)"
          ::Naf::Machine.assigned_jobs.each do |job|
            logger.warn "sending SIG_TERM to #{job.pid}: #{job.command}"
            Process.kill("TERM", job.pid)
          end

          (1..5).each do
            sleep(1)
            break if ::Naf::Machine.assigned_jobs.length == 0
          end

          assinged_jobs = ::Naf::Machine.assigned_jobs
          if assigned_jobs.length > 0
            logger.warn "terminating processes manually (forcing with SIG_KILL)"
            ::Naf::Machine.assigned_jobs.each do |job|
              logger.warn "sending SIG_KILL to #{job.pid}: #{job.command}"
              Process.kill("KILL", job.pid)
            end
          end
        end
      end
    end
  end
end
