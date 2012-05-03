module Af
  class QThread < Thread
    attr_reader :queue

    def initialize
      @queue = Queue.new
      super
    end

    def read_message
      return queue.pop
    end

    def post_message(message)
      queue << message
    end

    def request_termination(from = Thread.current)
      post_data_message(:terminate, from)
    end

    def post_data_message(data, from = Thread.current)
      post_message(::Af::QThread::Message.new(data, from))
    end
  end
end
