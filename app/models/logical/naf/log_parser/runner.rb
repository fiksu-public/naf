require 'yajl'

module Logical::Naf
  module LogParser
    class Runner < Base

      attr_accessor :search_params,
                    :regex_options,
                    :grep,
                    :search_from_time,
                    :search_to_time,
                    :last_line_checked,
                    :newest_line_checked,
                    :last_id_checked,
                    :newest_id_checked,
                    :stopped_at_id,
                    :log_type,
                    :newest_log,
                    :jsons,
                    :logs_size,
                    :read_from_s3,
                    :s3_log_reader,
                    :runner_id

      def initialize(params)
        super(params)
        @last_line_checked = params['last_line_number'].to_i
        @newest_line_checked = params['new_line_number'].to_i
        @last_id_checked = params['last_id_checked'].to_i
        @newest_id_checked = params['newest_id_checked'].to_i
        @stopped_at_id = nil
        @log_type = params['log_type']
        @newest_log = params['newest_log']
        @jsons = []
        @logs_size = 0
        @read_from_s3 = params['read_from_s3']
        @runner_id = params['record_id']
      end

      def logs
        if log_type == 'new'
          retrieve_new_logs
        elsif log_type == 'old'
          if read_from_s3 == 'true'
            @s3_log_reader = ::Logical::Naf::LogReader.new
          end
          retrieve_old_logs
        end
      end

      private

      def retrieve_old_logs
        line_number = parse_files

        output = ''
        new_line_number = newest_line_checked
        jsons.reverse_each do |elem|
          output.insert(0, "&nbsp;&nbsp;<span>#{elem['output_time']} <font color='333399'><b>invocation(#{elem['invocation_id']}):" +
            "</b></font> #{elem['message']}</br></span>")
        end

        return {
          logs: output.html_safe,
          last_line_number: line_number,
          new_line_number: new_line_number,
          stopped_at_id: stopped_at_id,
          read_from_s3: read_from_s3,
          newest_id_checked: newest_id_checked
        }
      end

      def retrieve_new_logs
        parse_new_files

        output = ''
        new_line_number = newest_line_checked
        new_id_checked = newest_id_checked
        if last_line_checked == 0 && last_id_checked == 0 && jsons.present?
          last_line_number = jsons.first['line_number']
          last_id = jsons.first['invocation_id']
        else
          last_line_number = last_line_checked
          last_id = last_id_checked
        end

        jsons.reverse_each do |elem|
          if output == ''
            new_line_number = elem['line_number']
            new_id_checked = elem['invocation_id']
          end
          output.insert(0, "&nbsp;&nbsp;<span>#{elem['output_time']} <font color='333399'><b>invocation(#{elem['invocation_id']}):" +
            "</b></font> #{elem['message']}</br></span>")
        end

        return {
          logs: output.html_safe,
          new_line_number: new_line_number,
          last_line_number: last_line_number,
          stopped_at_id: last_id,
          newest_id_checked: new_id_checked,
          read_from_s3: read_from_s3
        }
      end

      def parse_files
        files, line_number = find_files_not_read

        limit = nil
        files.each do |file|
          if logs_size > LOG_SIZE_CHUNKS
            info = file.scan(/\/\d+\/\d+_/).first
            invocation_id, line_number = info[1..-2].split('/')
            if limit.present? && limit != line_number
              @stopped_at_id = invocation_id

              return limit
            else
              limit = line_number
            end
          end

          # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
          parser = Yajl::Parser.new
          json = get_json_from_log_file(file)
          parser.parse(json) do |elem|
            filter_log_messages(elem)
          end

          # Sort log lines based on timestamp
          @jsons = jsons.sort { |x, y| Time.parse(x['output_time']) <=> Time.parse(y['output_time']) }
        end

        if logs_size <= LOG_SIZE_CHUNKS
          if files.present?
            info = files.last.scan(/\/\d+\/\d+_/).first
            @stopped_at_id, line_number = info[1..-2].split('/')
          elsif read_from_s3 == 'false'
            @stopped_at_id = last_id_checked
            line_number = last_line_checked
          end
          @read_from_s3 = 'true'
        else
          info = files.last.scan(/\/\d+\/\d+_/).first
          @stopped_at_id, line_number = info[1..-2].split('/')
        end

        # Reached the end of log files
        @stopped_at_id = -1 if stopped_at_id.nil?

        return line_number
      end

      def parse_new_files
        limit = nil
        find_new_files_not_read.each do |file|
          if logs_size > LOG_SIZE_CHUNKS
            info = file.scan(/\/\d+\/\d+_/).first
            invocation_id, line_number = info[1..-2].split('/')
            if limit.present? && limit != line_number
              @stopped_at_id = invocation_id

              return
            else
              limit = line_number
            end
          end

          # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
          parser = Yajl::Parser.new
          json = get_json_from_log_file(file)
          parser.parse(json) do |elem|
            filter_log_messages(elem)
          end

          # Sort log lines based on timestamp
          @jsons = jsons.sort do |x, y|
            sort_files(x, y)
          end
        end
      end

      def sort_files(x, y)
        if x.present? && y.present?
          Time.parse(x['output_time']).to_i <=> Time.parse(y['output_time']).to_i
        end
      end

      def get_json_from_log_file(file)
        if s3_log_reader.present?
          s3_log_reader.retrieve_file(file)
        else
          File.new(file, 'r')
        end
      end

      def find_files_not_read
        files = get_files

        line_number = nil
        if last_id_checked.present? && last_line_checked.present?
          if last_id_checked == -1
            # Reached the oldest file
            files = []
          else
            # Find the last log message displayed
            files.each_with_index do |file, index|
              # Retrieve the invocation_id and line_number associated with the log
              info = file.scan(/\/\d+\/\d+_/).first
              invocation_id, line_number = info[1..-2].split('/')

              # Compare the information from the log file with the information sent in params
              if invocation_id.to_i == last_id_checked && line_number.to_i <= last_line_checked
                # Filter the files not needed
                if line_number.to_i == last_line_checked
                  files = files[(index + 1)..-1]
                else
                  files = files[(index)..-1]
                end
                break
              end
            end
          end
        end

        return files, line_number
      end

      def find_new_files_not_read
        files = get_files

        if newest_id_checked.present? && newest_line_checked.present?
          files.each_with_index do |file, index|
            # Retrieve the invocation_id and line_number associated with the log
            info = file.scan(/\/\d+\/\d+_/).first
            invocation_id, line_number = info[1..-2].split('/')

            if invocation_id.to_i == newest_id_checked && line_number.to_i <= newest_line_checked
              files = files[0..index]
              break
            end
          end
        end

        return files
      end

      def get_files
        if log_type == 'old' && s3_log_reader.present?
          return s3_log_reader.runner_log_files(runner_id)
        else
          files = Dir["#{::Naf::PREFIX_PATH}/runners/*/invocations/*/*"]
          # Sort log files based on time
          files = files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }

          if files.empty?
            @s3_log_reader = ::Logical::Naf::LogReader.new
            @read_from_s3 = true
            return s3_log_reader.runner_log_files(runner_id)
          else
            return files
          end
        end
      end

      def filter_log_messages(log)
        # Check that the message matches the search query. Highlight the matching results
        match = Regexp.new(search_params, regex_options).match(log['message'])
        if match.to_s.present?
          log['message'].gsub!(match.to_s, "<span style='background-color:yellow;'>#{match.to_s}</span>")
        end

        # Check that the log happened within the time range specified
        if check_new_logs(log['line_number']) && log_within_time_range(log['output_time'])
          # If grep is selected, only show log messages that match the
          # search query. Otherwise, show all log messages.
          if grep == 'true'
            if log['message'] =~ Regexp.new(search_params, regex_options)
              @jsons << log
              @logs_size += 1
            end
          else
            @jsons << log
            @logs_size += 1
          end
        end
      end

    end
  end
end
