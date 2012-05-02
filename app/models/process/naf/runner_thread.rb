module Process::Naf
  class RunnerThread
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
  end
end
