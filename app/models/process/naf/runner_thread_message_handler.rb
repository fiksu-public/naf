module Process::Naf
  class RunnerThreadMessageHandler < ::Af::QThread::MessageHandler
    include ::Af::DaemonProcess::Proxy

    def process_message(message)
      logger.info message
    end
  end
end
