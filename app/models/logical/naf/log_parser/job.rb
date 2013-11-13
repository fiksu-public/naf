require 'yajl'

module Logical::Naf
  module LogParser
    class Job < Base

      def initialize(params)
        super(params)
      end

      def logs
        retrieve_logs
      end

      private

      def insert_log_line(elem)
        "&nbsp;&nbsp;<span>#{elem['line_number']} #{elem['output_time']}: #{elem['message']}</br></span>"
      end

      def sort_jsons
        # Sort log lines based on timestamp
        @jsons = jsons.sort { |x, y| x['line_number'] <=> y['line_number'] }
      end

      def parse_newest_log
        if newest_log.scan(/\d+ \d{4}-\d{2}-\d{2}/).present?
          newest_log.slice!(newest_log.split(/ /).first + ' ')
        end

        if newest_log.scan(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}:/).present?
          date = newest_log.slice!(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}:/)[0..-2]
          @newest_log = date + newest_log
        end
        newest_log
      end

      def retrieve_log_files_from_s3
        s3_log_reader.retrieve_job_files(record_id)
      end

      def get_files
        if log_type == 'old' && read_from_s3 == 'true'
          get_s3_files do
            @s3_log_reader = ::Logical::Naf::LogReader.new
            return s3_log_reader.retrieve_job_files(record_id)
          end
        else
          files = Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{record_id}/*"]
          # Sort log files based on time
          return files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }
        end
      end

    end
  end
end
