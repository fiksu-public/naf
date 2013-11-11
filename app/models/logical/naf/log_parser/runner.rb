require 'yajl'

module Logical::Naf
  module LogParser
    class Runner < Base

      attr_accessor :search_params,
                    :regex_options,
                    :grep,
                    :search_from_time,
                    :search_to_time,
                    :log_type,
                    :newest_log,
                    :jsons,
                    :logs_size,
                    :read_from_s3,
                    :s3_log_reader,
                    :invocations_ids,
                    :last_file_checked,
                    :newest_file_checked

      def initialize(params)
        super(params)
        @log_type = params['log_type']
        @newest_log = params['newest_log']
        @jsons = []
        @logs_size = 0
        @read_from_s3 = params['read_from_s3']
        @invocations_ids = {}
        @last_file_checked = params['last_file_checked']
        @newest_file_checked = params['newest_file_checked']
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
          output.insert(0, "&nbsp;&nbsp;<span>#{elem['output_time']} #{invocation_link(elem['id'])}: #{elem['message']}</br></span>")
        end

        return {
          logs: output.html_safe,
          read_from_s3: read_from_s3,
          last_file_checked: last_file_checked,
          newest_file_checked: newest_file_checked,
          newest_log: newest_log
        }
      end

      def invocation_link(id)
        "<a href=\"\/job_system\/machine_runner_invocations\/#{id}\" style=\"font-weight:bold; color: #333399\">invocation(#{id})</a>"
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
        "#{newest_log.scan(/\d{4}.*\.\d{3}/).first} #{newest_log.scan(/Process.*/).first.split('<br>').first}"
      end

      def parse_files
        filter_files.each do |file|
          # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
          parser = Yajl::Parser.new
          json = get_json_from_log_file(file)
          parser.parse(json) do |elem|
            filter_log_messages(elem, file)
          end

          # Sort log lines based on timestamp
          @jsons = jsons.sort { |x, y| Time.parse(x['output_time']) <=> Time.parse(y['output_time']) }

          if logs_size > LOG_SIZE_CHUNKS
            @last_file_checked = file.scan(/\d+_.*/).first
            break
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

      def filter_files
        files = get_files

        if last_file_checked.present?
          files.each_with_index do |file, index|
            filename = file.scan(/\d+_.*/).first

            if log_type == 'old'
              if filename == last_file_checked
                files = files[(index + 1)..-1]
              end

              if files.size == 0
                get_s3_files do
                  @s3_log_reader = ::Logical::Naf::LogReader.new
                  @read_from_s3 = true
                  files = s3_log_reader.runner_log_files(runner_id)
                end
              end
            elsif log_type == 'new'
              if filename == newest_file_checked.scan(/\d+_.*/).first
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
        if log_type == 'old' && s3_log_reader.present?
          get_s3_files do
            return s3_log_reader.runner_log_files(runner_id)
          end
        else
          files = Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/runners/*/*"]
          # Sort log files based on time
          files = files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }

          return files
        end
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

      def filter_log_messages(log, file)
        # Check that the message matches the search query. Highlight the matching results
        match = Regexp.new(search_params, regex_options).match(log['message'])
        if match.to_s.present?
          log['message'].gsub!(match.to_s, "<span style='background-color:yellow;'>#{match.to_s}</span>")
        end

        log['id'] = get_invocation_id(file.scan(UUID_REGEX).first)

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

      def get_invocation_id(uuid)
        if invocations_ids[uuid].blank?
          @invocations_ids[uuid] = ::Naf::MachineRunnerInvocation.find_by_uuid(uuid).id
        end

        invocations_ids[uuid]
      end

    end
  end
end
