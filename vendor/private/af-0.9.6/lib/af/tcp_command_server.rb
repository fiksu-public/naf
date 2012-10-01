module Af
  class TCPCommandServer
    include ::Af::Application::Proxy

    class NoMoreToDo < StandardError
    end
    class InvalidCommand < StandardError
    end

    attr_reader :server, :sessions, :server_hostname, :server_port
    attr_accessor :items

    def initialize(server_hostname, server_port)
      @server_hostname = server_hostname
      @server_port = server_port
      @server = TCPServer.new(server_hostname, server_port)
      @sessions = []
      @more_to_do = true
      @items = []
    end

    def logger
      return af_logger(self.class.name)
    end

    def more_to_do?
      return @more_to_do
    end

    def no_more_to_do!
      @more_to_do = false
    end

    def next_item
      return @items.shift
    end

    def command_reader(rfd)
      return rfd.readline.chomp
    end

    def command_dispatcher(line, rfd)
      dispatcher_command = "_command_#{line}".to_sym
      if self.respond_to?(dispatcher_command)
        self.send(dispatcher_command, rfd)
      else
        _unknown_command(line, rfd)
      end
    end

    def _unknown_command(line, rfd)
      raise InvalidCommand.new(dispatcher_command.to_s)
    end

    def _command_ready(rfd)
      if more_to_do?
        item = next_item
        if item
          logger.detail "requesting slave process: #{item}"
          rfd.write("#{item}\n")
        else
          no_more_to_do!
          raise NoMoreToDo.new
        end
      else
        raise NoMoreToDo.new
      end
    end

    def serve
      while true
        if !more_to_do? && sessions.blank?
          break
        end
        reads = [server] + sessions
        rfds, wfds, efds = IO.select(reads)
        if efds.present?
          logger.error "error: #{efds.inspect}"
          sessions -= efds
        end
        rfds.each do |rfd|
          logger.debug_fine "rfd: #{rfd.inspect}"
          if rfd == server
            nfd = server.accept
            if more_to_do?
              sessions << nfd
              logger.info "new slave: #{nfd.inspect}"
            else
              logger.warn "ignoring new slave: #{nfd.inspect}"
              nfd.close
            end
          else
            close_rfd = false
            begin
              # XXX need to keep track of which lines are processed by which slaves
              # XXX so we can retry processing when a slave crashes
              line = command_reader(rfd)
              command_dispatcher(line, rfd)
            rescue NoMoreToDo
              logger.info "closing slave connection: #{rfd.inspect}"
              close_rfd = true
            rescue InvalidCommand => e
              logger.warn "unknown request from slave: '#{e.message}': #{rfd.inspect}"
              close_rfd = true
            rescue EOFError
              logger.warn "slave closed connection: #{rfd.inspect}"
              close_rfd = true
            end
            if close_rfd
              logger.info "closing connection to slave: #{rfd.inspect}"
              sessions -= [rfd]
              rfd.close
            end
          end
        end
      end
    end
  end
end
