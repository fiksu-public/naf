require 'log4r/configurator'

module Af
  class DaemonProcess
    include ::Af::CommandLineToolMixin

    attr_accessor :has_errors, :daemon

    @@singleton = nil

    def self.singleton
      fail("@@singleton not initialized! Maybe you are using a Proxy before creating an instance?") unless @@singleton
      @@singleton
    end

    def initialize
      @@singleton = self
      @logger = nil
    end

    COMMAND_LINE_OPTIONS = {
      "--daemon" => {
        :short => "-d",
        :argument => GetOptions::NO_ARGUMENT,
        :note => "run as daemon"
      },
    }

    def name
      return self.class.name
    end

    def log4r_custum_levels
      Log4r::Configurator.custom_levels(:DEBUG, :INFO, :WARN, :ALARM, :ERROR, :FATAL)
    end

    def log4r_pattern_formatter_format
      return "%l %C %M"
    end

    def log4r_formatter
      return Log4r::PatternFormatter.new(:pattern => log4r_pattern_formatter_format)
    end

    def log4r_outputter
      return Log4r::StdoutOutputter.new("stdout", :formatter => log4r_formatter)
    end

    def logger_level
      return Log4r::ALL
    end

    def logger
      unless @logger
        log4r_custum_levels
        @logger = Log4r::Logger.new(name)
        @logger.outputters = log4r_outputter
        @logger.level = logger_level
      end
      return @logger
    end

    def self.run(*arguments)
      # this ARGV hack is here for test specs to add script arguments
      ARGV[0..-1] = arguments if arguments.length > 0
      self.new.run
    end

    def run(usage = nil, options = {})
      @options = options.merge(COMMAND_LINE_OPTIONS)
      @usage = (usage or "#{self.class.name} [OPTIONS]")

      command_line_options(@options, @usage)

      work unless handle_one_time_command_switches

      exit @has_errors ? 1 : 0
    end

    protected
    def option_handler(option, argument)
      if option == '--daemon'
        Daemons.daemonize
        cleanup_after_fork
      end
    end

    # Overload to impose constraints on parsed arguments.  MUST call super().
    # Return true to terminate immediately without calling work.
    # Return false for normal processing.
    def handle_one_time_command_switches
      return false
    end

    def cleanup_after_fork
      ActiveRecord::Base.connection.disconnect!
      ActiveRecord::Base.establish_connection
    end

    module Proxy
      def logger
        return ::Af::DaemonProcess.singleton.logger
      end

      def name
        return ::Af::DaemonProcess.singleton.name
      end
    end
  end
end
