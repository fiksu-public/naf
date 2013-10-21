require 'yajl'

module Logical::Naf
  module LogParser
    class Job < Base

      NAF_LOG_PATH = "#{::Naf::LOGGING_ROOT_DIRECTORY}/naflogs/#{NAF_DATABASE_HOSTNAME}/#{NAF_DATABASE}/#{NAF_SCHEMA}/jobs/"

	    attr_accessor :naf_job_id,
                    :end_position,
                    :last_line_checked,
                    :jsons,
                    :s3_log_reader,
                    :check_s3

    	def initialize(params, end_position = nil)
        super(params)
    		@naf_job_id = params['naf_job_id'].to_i
        @end_position = params['last_line_number'].to_i
    		@last_line_checked = params['last_line_number']
        @jsons = []
        @s3_log_reader = ::Logical::Naf::LogReader.new
        @check_s3 = false
    	end

      def logs
        parse_files

        output = ''
        last_line_number = last_line_checked
        jsons.reverse_each do |elem|
          if output == ''
            last_line_number = elem['line_number']
          end

          output.insert(0, "&nbsp;&nbsp;#{elem['output_time']}, #{elem['message']}</br>")
        end

        return {
          logs: output.html_safe,
          last_line_number: last_line_number
        }
      end

      private

      def parse_files
				get_files.each do |file|
					# Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
					parser = Yajl::Parser.new
					json = get_json_from_log_file(file)
					parser.parse(json) do |log|
            filter_log_messages(log)
          end

					# Sort log lines based on timestamp
					@jsons = jsons.sort{ |x, y| Time.parse(x['output_time']).to_i <=> Time.parse(y['output_time']).to_i }
				end
    	end

      def get_files
        files = Dir[NAF_LOG_PATH + "#{naf_job_id}/*"]

        if files.empty?
          @check_s3 = true
          files = s3_log_reader.retrieve_job_files(naf_job_id)
        end

        # Sort log files based on time
        files = files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }

        files
      end

      def get_json_from_log_file(file)
        if check_s3 && s3_log_reader.present?
          s3_log_reader.retrieve_file(file)
        else
          File.new(file, 'r')
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
            end
          else
            @jsons << log
          end
        end
      end

    	def check_new_logs(line_number)
    		if end_position.present?
					line_number.to_i > end_position
				else
					false
				end
    	end

  	end
  end
end
