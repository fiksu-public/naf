module Process:ScriptManager
  class Rope < Thread
    attr_reader :queue

    def initialize
      @queue = Queue.new
      super
    end
  end
end
