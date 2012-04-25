module Process:ScriptManager
  class RopeRunner
    def self.run
      return new.run
    end

    def run
      begin
        Rope.new do
          process_messages
        end
      rescue
      end
    end

    def process_messages
      while true
        message = read_message
        break if message.data == :terminate
        response = process_message(message)
        from.post_message(response, self)
      end
    end

    def process_message(message)
      return nil
    end

    def read_message
      return queue.pop
    end

    def post_message(message)
      queue << message
    end

    def post_to_thread(thread, message)
      thread.post_message(message)
    end
  end
end
