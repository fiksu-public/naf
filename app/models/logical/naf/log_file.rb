module Logical
  module Naf
    class LogFile
      LOG_MAX_SIZE = 10_000

      def initialize(log_area)
        @file_line_number = @line_number = 1
        @file = nil
        @log_area = log_area
        @lines_cache = ''
      end

      def <<(message, record_id = nil)
        log_line = JSON.pretty_generate({
          line_number: @line_number,
          output_time: Time.zone.now.strftime("%Y-%m-%d %H:%M:%S.%L"),
          message: message
         })
        @lines_cache << log_line
        @line_number += 1
      end

      def write
        check_file_size
        output = @lines_cache
        unless output.blank?
          @file.write(output)
          @lines_cache = ''
          flush
        end
      end

      def flush
        @file.flush
      end

      def open
        # Create the directory path if it doesn't exist
        FileUtils.mkdir_p(@log_area)

        filename = Dir[@log_area + "/#{@file_line_number}_*"].first
        if filename.blank?
          @file = File.open(@log_area + "/#{@file_line_number}_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.json", 'wb')
        else
          @file = File.open(filename, 'wb')
        end
      end

      def close
        @file.try(:close)
        @file = nil
      end

      def check_file_size
        if @file.size > LOG_MAX_SIZE
          @file_line_number = @line_number
          close
          @file = File.open(@log_area + "/#{@file_line_number}_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.json", 'wb')
        end
      end
    end

  end
end
