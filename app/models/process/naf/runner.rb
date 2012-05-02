module Process::Naf
  class Runner < Af::DaemonProcess
    def initialize
      @thread_pool_size = 10
      @check_schedules_period = 1.minute
      @check_schedules_alarm = 10.minutes
      @check_runners_period = 5.minutes
      @check_runners_alarm = 15.minutes
    end

    def work
      pool = Af::ThreadPool.new(@thread_pool_size)

      (1..@thread_pool_size).each do |n|
        pool.process do
          RunnerThread.run
        end
      end
      
      while true
        time = last_time_schedules_were_check
        if time < Time.zone.now - @check_schedules_period
          if try_lock_schedules
            schedule_tasks
            mark_schedules_checked
            unlock_schedules
          else
            if time < Time.zone.now - @check_schedules_alarm
              # XXX assume a machine is down and the lock is still held
              alarm
              unlock_schedules
            end
          end
        end

        time = last_time_runners_were_check
        if check_runners
          # XXX make sure a bunch of don't clog up if this routine takes long
          check_if_runners_are_alive
        end
        sleep(60)
      end

      pool.join()
    end
  end
end
