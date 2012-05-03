module Process::Naf
  class Runner < Af::DaemonProcess
    def initialize
      super
      @thread_pool_size = 10
      @check_schedules_period = 1.minute
      @runner_stale_period = 10.minutes
      @loop_sleep_time = 1.minute
    end

    def work
      pool = ::Af::ThreadPool.new(@thread_pool_size)

      (1..@thread_pool_size).each do |n|
        pool.process do
          RunnerThread.run
        end
      end
      
      while true
        machine = ::Naf::Machine.current
        break unless machine.present?
        break unless machine.enabled

        if ::Naf::Machine.it_is_time_to_check_schedules?(@check_schedules_period)
          if ::Naf::Schedule.try_lock_schedules
            machine.mark_checked_schedule
            ::Naf::Schedule.unlock_schedules

            # check scheduled tasks
            ::Naf::ApplicationSchedule.should_be_queued do |application_schedule|
              logger.info "schedule application: #{application_schedule.inspect}"
            end

            # check the runner machines
            ::Naf::Machine.enabled.each do |runner_to_check|
              runner_to_check.mark_alive if runner_to_check.runner_alive

              if runner_to_check.is_stale?(@runner_stale_period)
                logger.alarm "runner down #{runner_to_check.inspect}"
                runner_to_check.mark_machine_dead
              end
            end
          end
        end

        sleep(@loop_sleep_time)
      end

#      pool.workers.each do |worker|
#        worker.request_termination
#      end

      pool.join()
    end
  end
end
