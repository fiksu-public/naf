module Process::Naf
  class X
    def run
      system("echo hi; sleep 10")
    end
  end

  class RunnerThread
    include ::Af::DaemonProcess::Proxy

    def self.run
      return self.new.run
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
      return Process::Naf::X.new
    end
  end
end
