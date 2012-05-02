module Process::Naf
  class Runner < Af::DaemonProcess
    def initialize
      @primary_runner = false
      @thread_pool_size = 10
    end

    def work
      pool = Af::ThreadPool.new(@thread_pool_size)

      (1..@thread_pool_size).each do |n|
        pool.process do
          RunnerThread.run
        end
      end
      
      while true
        if is_primary_runner?
          schedule_tasks
          check_if_runners_are_alive
        else
          check_if_primary_alive
        end
        sleep(60)
      end

      pool.join()
    end

    def is_primary_runner?
      # lock table
      # is there a primary runner?
      #   yes
      #     are we it?
      #      yes - return true
      #      no - ensure we don't think we are the primary; return false
      #   no
      #     do we think we are primary?
      #       yes - ensure we are running as primary; return true
      #       no - start running as primary; return true
      # unlock table
    end

  end
end
