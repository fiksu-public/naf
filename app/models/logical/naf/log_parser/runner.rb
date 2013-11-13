require 'yajl'

module Logical::Naf
  module LogParser
    class Runner < Base

      attr_accessor :invocations_ids

      def initialize(params)
        super(params)
        @invocations_ids = {}
      end

      def logs
        retrieve_logs
      end

      private

      def insert_log_line(elem)
        "&nbsp;&nbsp;<span>#{elem['output_time']} #{invocation_link(elem['id'])}: #{elem['message']}</br></span>"
      end

      def invocation_link(id)
        "<a href=\"\/job_system\/machine_runner_invocations\/#{id}\" style=\"font-weight:bold; color: #333399\">invocation(#{id})</a>"
      end

      def sort_jsons
        # Sort log lines based on timestamp
        @jsons = jsons.sort { |x, y| Time.parse(x['output_time']) <=> Time.parse(y['output_time']) }
      end

      def parse_newest_log
        "#{newest_log.scan(/\d{4}.*\.\d{3}/).first} #{newest_log.scan(/Process.*/).first.split('<br>').first}"
      end

      def retrieve_log_files_from_s3
        s3_log_reader.runner_log_files(record_id)
      end

      def get_invocation_id(uuid)
        if invocations_ids[uuid].blank?
          @invocations_ids[uuid] = ::Naf::MachineRunnerInvocation.find_by_uuid(uuid).id
        end

        invocations_ids[uuid]
      end

      def get_files
        if log_type == 'old' && read_from_s3 == 'true'
          get_s3_files do
            @s3_log_reader = ::Logical::Naf::LogReader.new
            return s3_log_reader.runner_log_files(record_id)
          end
        else
          files = Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/runners/*/*"]
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

    end
  end
end
