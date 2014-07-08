module Logical::Naf
  module LogParser
    class JobDownloader < Base

      ############################################################################
      # Description
      # -----------
      # Logical model to return the contents of all log files
      #   associated with a specific job ID.
      #
      # Interface
      # ---------
      # initialize: Pass intitialize a hash of only one parameter ('record_id')
      #     Initializes the JobDownloader by linking it to a record_id
      #
      # logs_for_download: Takes no arguments
      #     Returns a string containing all parsed log messages (plain text)
      #     from all local and S3 files associated with the JobDownloader's
      #     record_id.
      #
      ############################################################################

      # Description: Initializes instance variables for the class
      # params: Params must include 'record_id' key/value
      # Note: Only uses record_id from params 
      def initialize(params)
        @jsons = []
        @record_id = params['record_id']
        @read_from_s3 = true;
      end

      # Description: Public method used to return a string of all logs
      #     The string contains all parsed json elements from all
      #     accessible files (local and s3) for @record_id
      # Returns: String (of logs)
      def logs_for_download
        retrieve_logs_for_download
      end

      ###################################################
      private
      ###################################################

      # Description: Returns a string containing all parsed json elements form all
      #     accessible files (local and s3) for @record_id
      # Returns: String (of logs)
      def retrieve_logs_for_download
        parse_files_for_download

        output = ''
        jsons.reverse_each do |elem|
          output.insert(0, insert_log_line_for_download(elem))
        end

        output
      end

      # Description: Formats a single log line
      # elem: Takes in a hash of a single log entry,
      #     (originating from Yajl::Parser parsing json)
      # Returns: String (single log line, formatted as plain text, without any added html)
      def insert_log_line_for_download(elem)
        if elem['message'].include? "AWS S3 Access Denied. Please check your permissions"
          # If it cannot access AWS S3, the JobDownlaoder will still return all the logs stored locally.
          output_line = ""
        else
          output_line = "#{elem['line_number']} #{elem['output_time']}: #{elem['message']}\n"
        end

        return output_line
      end

      # Acts on instance variable @jsons (sorts them)
      def sort_jsons
        # Sort log lines based on timestamp
        @jsons = jsons.sort { |x, y| x['line_number'] <=> y['line_number'] }
      end

      # Calls the Logical::Naf::LogReader retrieve_job_files method for record_id
      # Returns: Array of file names on S3 corresponding to record_id
      def retrieve_log_files_from_s3
        s3_log_reader.retrieve_job_files(record_id)
      end

      # Description: Finds file names (across local and S3) associated with record_id
      # Returns: Hash (file_name => is_on_s3_bool)
      def get_files_for_download
        files_to_download = {}
        s3_files = []
       
        # S3
        get_s3_files do
          @s3_log_reader = ::Logical::Naf::LogReader.new
          s3_files = retrieve_log_files_from_s3
        end

        # Add S3 files to the hash, mapping them to true (need to read from s3)
        s3_files.each do |file_to_add|
          files_to_download[file_to_add] = true
        end

        return files_to_download unless record_id.present?

        # Non-S3
        if File.directory?("#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{record_id}")
          files = Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{record_id}/*"]
        else
          return files_to_download
        end

        if files.present?
          # Sort log files based on time and add them the hash (mapped to false)
          files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }.each do |file_to_add|
            files_to_download[file_to_add] = false
          end
        end

        return files_to_download
      end

      # Either read local file or retrieve contents from s3 as needed
      # Returns contents of file
      def get_json_from_log_file_for_download(file)
        if @read_from_s3 == true
          if s3_log_reader.present?
            s3_log_reader.retrieve_file(file)
          end
        else
          File.new(file, 'r')
        end
      end

      # Retrieves file_names and iterates through them, using yajl to parse the json
      # Adds all jsons to the instance variable @jsons
      def parse_files_for_download
        files = get_files_for_download # now a hash

        unless files.present?
          return ""
        else
          files.each_pair do |file, s3_needed|
            # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
            parser = Yajl::Parser.new
            @read_from_s3 = s3_needed
            json = get_json_from_log_file_for_download(file)
            parser.parse(json) do |log|
              @jsons << log
            end
            sort_jsons
          end
        end
      end

    end
  end
end
