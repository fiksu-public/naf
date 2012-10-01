module Af
  class TCPCommandClient
    include ::Af::Application::Proxy

    attr_reader :client, :server_hostname, :server_port

    def initialize(server_hostname, server_port)
      @server_hostname = server_hostname
      @server_port = server_port
      @client = TCPSocket.new(server_hostname, server_port)
    end

    def logger
      return af_logger(self.class.name)
    end

    def command_reader
      return client.readline.chomp
    end

    def command_dispatcher(line)
      logger.debug_fine "process command: #{line}"
    end

    def reply_to_server(line)
      client.write("#{line}\n")
    end

    def ready
      reply_to_server("ready")
    end

    def serve
      while true
        logger.debug_medium "READY!"
        ready
        begin
          line = command_reader
          logger.debug_fine "working on: #{line}"
          command_dispatcher(line)
        rescue EOFError
          logger.warn "master closed connection: #{client.inspect}"
          client.close
          break
        end
      end
    end
  end
end
