module Af::QThread
  class Base < Thread
    attr_reader :queue

    def initialize
      @queue = Queue.new
      super
    end

    include ::Af::QThread::Interface

    def request_termination(from = Thread.current)
      post_data_message(:terminate, from)
    end

    def kick_start(from = Thread.current)
      post_data_message(:kick_start, from)
    end
  end
end
