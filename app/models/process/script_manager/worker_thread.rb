module Process:ScriptManager
  class WorkerThread
    class Message
      MessageTypes = [START = 0, DIE = 1, DEAD = 2, DATA = 3]

      attr_reader :message_type, :from, :to, :data

      def initialize(from, to, data, message_type = DATA)
        @message_type = message_type
        @from = from
        @to = to
        @data = data
      end

      def process
      end

      def respond(data, responder = nil)
        message = Message.new(responder || to, data)
        message.post(from)
      end

      def post(to)
        to.post_message(self)
      end
    end

    attr_reader :owner, :queue
    def initialize(owner)
      @owner = owner
      @queue = Queue.new
    end

    def self.run(owner)
      new(owner).run
    end

    def run
      begin
        Thread.new do
          work
        end
      rescue
      end
      post_to_thread(owner, Message.new(self, )
    end

    def work
      while true
        request = read_message
        break if request == DIE
        request.respond(request.process, self)
      end
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
