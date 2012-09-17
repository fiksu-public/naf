require 'thread'

# stolen from the web
#   http://snippets.dzone.com/posts/show/3276

module Af
  class ThreadPool
    class Worker
      attr_reader :thread

      def initialize(thread_class = Thread)
        @mutex = Mutex.new
        @thread = thread_class.new do
          while true
            sleep 0.001
            block = get_block
            if block
              block.call
              reset_block
            end
          end
        end
      end

      def get_block
        @mutex.synchronize {@block}
      end

      def set_block(block)
        @mutex.synchronize do
          raise RuntimeError, "Thread already busy." if @block
          @block = block
        end
      end

      def reset_block
        @mutex.synchronize {@block = nil}
      end

      def busy?
        @mutex.synchronize {!@block.nil?}
      end
    end

    attr_accessor :max_size, :thread_class
    attr_reader :workers

    def initialize(max_size = 10, thread_class = Thread)
      @max_size = max_size
      @workers = []
      @mutex = Mutex.new
      @thread_class = thread_class
    end

    def size
      @mutex.synchronize {@workers.size}
    end

    def busy?
      @mutex.synchronize {@workers.any? {|w| w.busy?}}
    end

    def join
      sleep 0.01 while busy?
    end

    def process(&block)
      while true
        @mutex.synchronize do
          worker = find_available_worker 
          if worker
            return worker.set_block(block)
          end
        end
        sleep 0.01
      end
    end

    def wait_for_worker
      while true
        worker = find_available_worker
        return worker if worker
        sleep 0.01
      end
    end

    def find_available_worker
      free_worker || create_worker
    end

    def free_worker
      @workers.each {|w| return w unless w.busy?}; nil
    end

    def create_worker
      return nil if @workers.size >= @max_size
      worker = Worker.new(@thread_class)
      @workers << worker
      worker
    end
  end
end
