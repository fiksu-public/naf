module Af::QThread
  class Message
    attr_accessor :from, :data, :msg_id
    def initialize(data, from = Thread.current)
      @from = from
      @data = data
      @msg_id = self.class.new_msg_id
    end

    def self.new_msg_id
      return UUID.new
    end
  end
end
