module Af::QThread::Interface
  def has_message?
    return !queue.empty?
  end

  def read_message
    return queue.pop
  end

  def post_message(message)
    queue << message
  end

  def requeue(message)
    post_message(message)
  end

  def post_data_message(data, from = Thread.current)
    post_message(::Af::QThread::Message.new(data, from))
  end
end
