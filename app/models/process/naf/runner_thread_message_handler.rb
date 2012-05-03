module Process::Naf
  class RunnerThreadMessageHandler < ::Af::QThread::MessageHandler
    include ::Af::DaemonProcess::Proxy

    def process_message(message)
      if message.data == :kick_start
        logger.info "kicked!"
        return :more
      else
        logger.info message
        return :completed
      end
    end
  end
end
