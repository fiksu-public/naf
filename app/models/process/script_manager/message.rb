module Process:ScriptManager
  class Message
    attr_accessor :from, :data, :msg_id
    def initialize(from, data)
      @from = from
      @data = data
      @msg_id = self.class.new_msg_id
    end

    def self.new_msg_id
      return UUID.new
    end
  end
end
