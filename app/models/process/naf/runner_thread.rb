module Process::Naf
  class RunnerThread
    include ::Af::DaemonProcess::Proxy

    def self.run
      new.run
    end

    def run
      while true
        command = pick_something_off_queue
        if command
          command.run
        else
          sleep(60)
        end
      end
    end

    def pick_something_off_queue
      return nil
    end
  end
end
