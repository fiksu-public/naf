module Process::Naf
  class Runner < Af::DaemonProcess
    def initialize
      @thread_pool_size = 10
      @check_schedules_period = 1.minute
    end

    def work
      pool = Af::ThreadPool.new(@thread_pool_size)

      (1..@thread_pool_size).each do |n|
        pool.process do
          RunnerThread.run
        end
      end
      
      while true
        machine = Naf::Machine.current
        break unless machine.present?
        break unless machine.enabled

        time = Naf::Machine.last_time_schedules_were_checked
        if time.nil? || time < Time.zone.now - @check_schedules_period
          if Naf::Schedule.try_lock_schedules
            # check scheduled tasks
            machine.last_checked_schedules_at = Time.zone.now
            machine.save
            Naf::Schedule.unlock_schedules

            schedule_tasks

            # check the runner machines
            Naf::Machine.where('enabled').each do |enabled_machine|
              unless enabled_machine.runner_alive
                enabled_machine.set_alive
                enabled_machine.save
              end

              if enabled_machine.stale
                logger.alarm "runner down #{enabled_machine.inspect}"
                enabled_machine.enabled = false
                enabled_machine.save
                enabled_machine.mark_processes_as_dead
              end
            end
          end
        end

        sleep(60)
      end

      pool.workers.each do |worker|
        worker.request_termination
      end

      pool.join()
    end
  end
end
