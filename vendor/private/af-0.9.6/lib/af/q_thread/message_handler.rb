module Af::QThread
  class MessageHandler
    attr_reader :thread

    def initialize(thread)
      @thread = thread
    end

    def self.run(thread = Thread.current)
      return new(thread).run
    end

    def run
      process_messages
    end

    def process_messages
      while true
        message = thread.read_message
        break if message.data == :terminate
        response = process_message(message)
        message.from.post_data_message(response, thread)
      end
    end

    def process_message(message)
      return nil
    end
  end
end
