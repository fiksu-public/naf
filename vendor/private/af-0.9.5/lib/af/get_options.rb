require 'getoptlong'

module Af
  class GetOptions < GetoptLong
    ARGUMENT_FLAGS = [
      NO_ARGUMENT = GetoptLong::NO_ARGUMENT,
      REQUIRED_ARGUMENT = GetoptLong::REQUIRED_ARGUMENT,
      OPTIONAL_ARGUMENT = GetoptLong::OPTIONAL_ARGUMENT
    ]

    def initialize(switches = {})
      @command_line_switchs = switches
      @environment_variables = {}
      @getopt_options = []

      switches.each{|long_switch,parameters|
        if parameters[:environment_variable].present?
          @environment_variables[parameters[:environment_variable]] = long_switch
        end

        options = []
        options << long_switch
        if (parameters[:short])
          options << parameters[:short]
        end
        options << parameters[:argument]
        @getopt_options << options
      }

      argv_additions = []
      for environment_variable_name,value in @environment_variables do
        if ENV[environment_variable_name]
          argv_additions << value
          argv_additions << ENV[environment_variable_name] unless ENV[environment_variable_name].empty?
        end
      end
      for arg in ARGV do
        argv_additions << arg
      end

      argv_additions.each_with_index{|v,i| ARGV[i] = v }

      super(*@getopt_options)
    end
  end
end
