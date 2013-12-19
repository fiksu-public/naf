require 'yajl'

module Logical::Naf
  module LogParser
    class Machine < Base

      def initialize(params)
        super(params)
      end

      def logs
        retrieve_logs
      end

      private

      def insert_log_line(elem)
        "&nbsp;&nbsp;<span>#{elem['output_time']} <font color='333399'><b>jid(#{elem['job_id']}):</b></font> #{elem['message']}</br></span>"
      end

      def sort_jsons
        # Sort log lines based on timestamp
        @jsons = jsons.sort { |x, y| Time.parse(x['output_time']) <=> Time.parse(y['output_time']) }
      end

      def parse_newest_log
        if newest_log.scan(/jid\(\d*\)\: /).present?
          newest_log.slice!(/jid\(\d*\)\: /)
        end
        newest_log
      end

      def retrieve_log_files_from_s3
        s3_log_reader.log_files
      end

      def get_files
        if log_type == 'old' && read_from_s3 == 'true'
          get_s3_files do
            @s3_log_reader = ::Logical::Naf::LogReader.new
            return retrieve_log_files_from_s3
          end
        else
          files = Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/*/*"]
          if files.present?
            # Sort log files based on time
            return files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }
          else
            get_s3_files do
              @read_from_s3 = 'true'
              @s3_log_reader = ::Logical::Naf::LogReader.new
              return retrieve_log_files_from_s3
            end
          end
        end
      end

      def get_job_id(file)
        file.scan(/\d+_\d{8}/).first.split('_').first
      end

    end
  end
end
