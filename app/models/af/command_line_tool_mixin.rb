module Af
  module CommandLineToolMixin
    # options
    #  :short
    #  :argument_note
    #  :environment_variable
    #  :note
    #  :argument
    #
    #  :method - raise error if bad
    #  :exit_if_present
    #  :assignment

    def columnized_row(fields, sized)
      r = []
      fields.each_with_index do |f, i|
        r << sprintf("%0-#{sized[i]}s", f.to_s.gsub(/\\n\\r/, '').slice(0, sized[i]))
      end
      r.join('   ')
    end

    def columnized(rows, options = {})
      sized = {}
      rows.each do |row|
        row.each_index do |i|
          value = row[i]
          sized[i] = [sized[i].to_i, value.to_s.length].max
          sized[i] = [options[:max_width], sized[i].to_i].min if options[:max_width]
        end
      end

      table = []
      rows.each { |row| table << "    " + columnized_row(row, sized).rstrip }
      table.join("\n")
    end

    def help(command_line_usage, command_line_options)
      puts(command_line_usage)
      rows = []
      command_line_options.keys.sort.each{|long_switch|
        parameters = command_line_options[long_switch]
        columns = []
        switches = "#{long_switch}"
        if (parameters[:short])
          switches += " | #{parameters[:short]}"
        end
        if (parameters[:argument_note])
          switches += " #{parameters[:argument_note]}"
        end
        columns << switches
        columns << parameters[:note]
        columns << (parameters[:environment_variable] or "")
        rows << columns
      }
      puts(columnized(rows))
    end

    def command_line_options(options, usage)
      options.merge!({
                       "--?" => {
                         :short => "-?",
                         :argument => GetoptLong::NO_ARGUMENT,
                         :note => "show this help"
                       },
                     })
      get_options = Af::GetOptions.new(options)
      get_options.each{|option,argument|
        if option == '--?'
          help(usage, options)
          exit 0
        else
          option_handler(option, argument)
        end
      }
    end
  end
end
