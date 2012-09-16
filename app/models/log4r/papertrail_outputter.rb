require 'log4r/formatter/patternformatter'

module Log4r
  class PapertrailOutputter < RemoteSyslogOutputter
    def initialize(name, options)
      cloned_options = options.clone
      unless cloned_options.has_key?('url')
        if cloned_options.has_key?('port')
          cloned_options['url'] = "syslog://logs.papertrailapp.com:#{cloned_options['port']}"
        end
      end
      if cloned_options.has_key?('program')
        program_formatter = Log4r::PatternFormatter.new('pattern' => cloned_options['program'])
        cloned_options['program'] = program_formatter.format("").chomp
      end
      super(name, cloned_options)
    end
  end
end
