require 'yajl'

module Logical::Naf
  module LogParser
    class Base

      REGEX_OPTIONS = {
        'i' => Regexp::IGNORECASE,
        'x' => Regexp::EXTENDED,
        'm' => Regexp::MULTILINE
      }
      DATE_REGEX = /((\d){8}_(\d){6})/
      UUID_REGEX = /[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/
      LOG_SIZE_CHUNKS = 500

      attr_accessor  :search_params,
                     :regex_options,
                     :grep,
                     :search_from_time,
                     :search_to_time,
                     :jsons,
                     :logs_size,
                     :log_type,
                     :newest_log,
                     :record_id,
                     :read_from_s3,
                     :s3_log_reader,
                     :last_file_checked,
                     :newest_file_checked

      def initialize(params)
        @search_params = params['search_params'].nil? ? '' : params['search_params']
        @regex_options = get_option_value(params['regex_options'])
        @grep = params['grep']
        @search_from_time = params['from_time']
        @search_to_time = params['to_time']
        @jsons = []
        @logs_size = 0
        @log_type = params['log_type']
        @newest_log = params['newest_log']
        @record_id = params['record_id']
        @read_from_s3 = params['read_from_s3']
        @last_file_checked = params['last_file_checked']
        @newest_file_checked = params['newest_file_checked']
      end

      def retrieve_logs
        parse_files

        check_repeated_logs

        output = ''
        jsons.reverse_each do |elem|
          output.insert(0, insert_log_line(elem))
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
        if log['message'].scan(/\t/).present?
          message = log['message'].clone
          message.slice!('<top (required)>')
          "#{log['output_time']} #{message}"
        else
          "#{log['output_time']} #{log['message']}"
        end
      end

      def parse_files
        files = filter_files

        files.each do |file|
          # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
          parser = Yajl::Parser.new
          json = get_json_from_log_file(file)
          parser.parse(json) do |log|
            if self.class.to_s == 'Logical::Naf::LogParser::Runner'
              log['id'] = get_invocation_id(file.scan(UUID_REGEX).first)
            end
            log['message'] = CGI::escapeHTML(log['message'])
            filter_log_messages(log)
          end

          sort_jsons

          if logs_size >= LOG_SIZE_CHUNKS
            update_last_file_checked(file.scan(/\d+_\d{8}_\d{6}.*/).first)
            break
          end
        end

        if logs_size < LOG_SIZE_CHUNKS && files.present?
           update_last_file_checked(files.last.scan(/\d+_\d{8}_\d{6}.*/).first)
        end
      end

      def update_last_file_checked(file)
        if file.present? && last_file_checked.present? && last_file_checked != 'null'
          if Time.parse(file.scan(/\d{8}_\d{6}/).first) < Time.parse(last_file_checked.scan(/\d{8}_\d{6}/).first)
            @last_file_checked = file
          end
        elsif file.present?
          @last_file_checked = file
        end
      end

      def get_json_from_log_file(file)
        if read_from_s3 == 'true' && s3_log_reader.present?
          s3_log_reader.retrieve_file(file)
        else
          File.new(file, 'r')
        end
      end

      def filter_files
        files = get_files
        original_size = files.size

        files.each_with_index do |file, index|
          filename = file.scan(/\d+_\d{8}_\d{6}.*/).first

          if log_type == 'old'
            if filename == last_file_checked
              if files.size == 1
                files = []
              else
                files = files[(index + 1)..-1]
              end
            end

            if files.size == 0 && read_from_s3 != 'true'
              get_s3_files do
                @read_from_s3 = 'true'
                @s3_log_reader = ::Logical::Naf::LogReader.new
                return retrieve_log_files_from_s3
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

          break if original_size != files.size
        end

        if files.present?
          if newest_file_checked.blank? || newest_file_checked == 'null'
            @newest_file_checked = files[0].scan(/\d+_\d{8}_\d{6}.*/).first
          else
            if Time.parse(newest_file_checked.scan(DATE_REGEX)[0][0]) < Time.parse(files[0].scan(DATE_REGEX)[0][0])
              @newest_file_checked = files[0].scan(/\d+_\d{8}_\d{6}.*/).first
            end
          end
        end

        return files
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

      def log_within_time_range(log_time)
        return true if (search_from_time.join('').blank? && search_to_time.join('').blank?) || log_time.blank?

        if search_from_time.join('').present? && search_to_time.join('').present?
          Time.parse(log_time) <= Time.parse(build_time_string(search_to_time)) &&
          Time.parse(log_time) >= Time.parse(build_time_string(search_from_time))
        elsif search_from_time.join('').present?
          Time.parse(log_time) >= Time.parse(build_time_string(search_from_time))
        elsif search_to_time.join('').present?
          Time.parse(log_time) <= Time.parse(build_time_string(search_to_time))
        end
      end

      def build_time_string(search_time)
        # Year
        search_built_time = search_time[0] + "-"
        # Month
        if search_time[1].to_i < 10
          search_built_time << '0' + search_time[1] + '-'
        else
          search_built_time << search_time[1] + '-'
        end
        # Day
        if search_time[2].to_i < 10
          search_built_time << '0' + search_time[2] + ' '
        else
          search_built_time << search_time[2] + ' '
        end
        # Hour
        search_built_time << search_time[3] + ':'
        # Minute
        if search_time[4].to_i < 10
          search_built_time << '0' + search_time[4]
        else
          search_built_time << search_time[4]
        end
        # Second
        search_built_time << ':00 -0500'

        search_built_time
      end

      def get_option_value(options)
        return 0 if options.blank?

        options = options.split(//)
        result = 0
        options.each do |opt|
          result |= REGEX_OPTIONS[opt]
        end

        result
      end

      def get_s3_files
        begin
          yield
        rescue
          @jsons << {
            'line_number' => 0,
            'output_time' => Time.zone.now.strftime("%Y-%m-%d %H:%M:%S.%L"),
            'message' => 'AWS S3 Access Denied. Please check your permissions.'
          }

          return []
        end
      end

    end
  end
end
