require 'yajl'

module Logical::Naf
  module LogParser
    class Job < Base

      attr_accessor :naf_job_id,
                    :end_position,
                    :last_line_checked,
                    :newest_line_checked,
                    :jsons,
                    :s3_log_reader,
                    :check_s3,
                    :read_from_s3,
                    :naf_job_id,
                    :log_type,
                    :logs_size,
                    :newest_file_checked,
                    :last_file_checked,
                    :newest_log

      def initialize(params, end_position = nil)
        super(params)
        @naf_job_id = params['naf_job_id'].to_i
        @last_file_checked = params['last_file_checked']
        @newest_file_checked = params['newest_file_checked']
        @jsons = []
        @check_s3 = false
        @read_from_s3 = params['read_from_s3']
        @naf_job_id = params['record_id']
        @log_type = params['log_type']
        @newest_log = params['newest_log']
        @logs_size = 0
      end

      def logs
        retrieve_logs
      end

      private

      def retrieve_logs
        parse_files

        check_repeated_logs

        output = ''
        jsons.reverse_each do |elem|
          output.insert(0, "&nbsp;&nbsp;<span>#{elem['line_number']} #{elem['output_time']}: #{elem['message']}</br></span>")
        end

        return {
          logs: output.html_safe,
          read_from_s3: read_from_s3,
          last_file_checked: last_file_checked,
          newest_file_checked: newest_file_checked,
          newest_log: newest_log
        }
      end

      def check_repeated_logs
        if log_type == 'new' && newest_log.present?
          @jsons.each_with_index do |elem, index|
            if parse_log(elem) == parse_newest_log
              @jsons = @jsons[(index + 1)..-1]
              return
            end
          end
        end
      end

      def parse_log(log)
        "#{log['output_time']} #{log['message']}"
      end

      def parse_newest_log
        if newest_log.scan(/: .*/).first[3..3] == '/'
          "#{newest_log.scan(/\d{4}.*\.\d{3}/).first} #{newest_log.scan(/: .*/).first[2..-1].split('<br>').first[0..-6]}>\'"
        else
          "#{newest_log.scan(/\d{4}.*\.\d{3}/).first} #{newest_log.scan(/: .*/).first[2..-1].split('<br>').first}"
        end
      end

      def parse_files
        files = filter_files

        files.each do |file|
          # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
          parser = Yajl::Parser.new
          json = get_json_from_log_file(file)
          parser.parse(json) do |log|
            filter_log_messages(log)
          end

          # Sort log lines based on timestamp
          @jsons = jsons.sort{ |x, y| x['line_number'] <=> y['line_number'] }

          if logs_size >= LOG_SIZE_CHUNKS
            @last_file_checked = file.scan(/\d+_.*/).first
            break
          end
        end

        if logs_size < LOG_SIZE_CHUNKS && files.present?
           @last_file_checked = files.last.scan(/\d+_.*/).first
        end
      end

      def filter_files
        files = get_files

        files.each_with_index do |file, index|
          filename = file.scan(/\d+_.*/).first

          if log_type == 'old'
            if filename == last_file_checked
              if files.size == 1
                files = []
              else
                files = files[(index + 1)..-1]
              end
            end

            if files.size == 0
              get_s3_files do
                @read_from_s3 = 'true'
                @s3_log_reader = ::Logical::Naf::LogReader.new
                return s3_log_reader.retrieve_job_files(naf_job_id)
              end
            end
          elsif log_type == 'new'
            if filename == newest_file_checked
              if files.size == 1
                files = []
              else
                files = files[0..(index - 1)]
              end
            end
          end
        end

        if files.present?
          if newest_file_checked.blank?
            @newest_file_checked = files[0].scan(/\d+_.*/).first
          else
            if Time.parse(newest_file_checked.scan(DATE_REGEX)[0][0]) < Time.parse(files[0].scan(DATE_REGEX)[0][0])
              @newest_file_checked = files[0].scan(/\d+_.*/).first
            end
          end
        end

        return files
      end

      def get_files
        if log_type == 'old' && read_from_s3 == 'true'
          get_s3_files do
            @s3_log_reader = ::Logical::Naf::LogReader.new
            return s3_log_reader.retrieve_job_files(naf_job_id)
          end
        else
          files = Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{naf_job_id}/*"]
          # Sort log files based on time
          return files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }
        end
      end

      def get_json_from_log_file(file)
        if read_from_s3 == 'true' && s3_log_reader.present?
          s3_log_reader.retrieve_file(file)
        else
          File.new(file, 'r')
        end
      end

      def filter_log_messages(log)
        # Check that the message matches the search query. Highlight the matching results
        if search_params.present?
          log['message'].scan(Regexp.new(search_params, regex_options)).each do |match|
            log['message'].gsub!(match, "<span style='background-color:yellow;'>#{match}</span>")
          end
        end

        # Check that the log happened within the time range specified
        if log_within_time_range(log['output_time'])
          # If grep is selected, only show log messages that match the
          # search query. Otherwise, show all log messages.
          if grep == 'false' || log['message'] =~ Regexp.new(search_params, regex_options)
            @jsons << log
            @logs_size += 1
          end
        end
      end

    end
  end
end
