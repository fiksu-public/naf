require 'yajl'

module Process::Naf
  class LogReader < ::Process::Naf::Application

    opt :job_id, type: :int
    opt :runner_id, type: :int
    opt_select :job_id_or_runner_id, one_of: [:job_id, :runner_id]

    UUID_REGEX = /[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/

    attr_accessor :read_from_s3,
                  :s3_log_reader,
                  :jsons

  	def work
      @jsons = []
  		if @job_id.present?
        job_log_files.each do |file|
          # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
          parser = Yajl::Parser.new
          json = get_json_from_log_file(file)
          parser.parse(json) do |log|
            @jsons << log
          end

          sort_jsons
        end

        if jsons.present?
          jsons.each do |elem|
            puts insert_log_line(elem)
          end
        else
          puts 'No logs found'
        end
  		elsif @runner_id.present?
        runner_log_files.each do |file|
          # Use Yajl JSON library to parse the log files, as they contain multiple JSON blocks
          parser = Yajl::Parser.new
          json = get_json_from_log_file(file)
          parser.parse(json) do |log|
            log['id'] = get_invocation_id(file.scan(UUID_REGEX).first)
            @jsons << log
          end

          sort_jsons
        end

        if jsons.present?
          jsons.each do |elem|
            puts insert_log_line(elem)
          end
        else
          puts 'No logs found'
        end
  		end
  	end

  	private

    def job_log_files
      files = Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{@job_id}/*"]
      if files.present?
        @read_from_s3 = false
        # Sort log files based on time
        return files.sort { |x, y| Time.parse(y.scan(::Logical::Naf::LogParser::Base::DATE_REGEX)[0][0]) <=> Time.parse(x.scan(::Logical::Naf::LogParser::Base::DATE_REGEX)[0][0]) }
      else
        get_s3_files do
          @read_from_s3 = true
          @s3_log_reader = ::Logical::Naf::LogReader.new
          return s3_log_reader.retrieve_job_files(@job_id)
        end
      end
    end

    def runner_log_files
      invocation_uuids = ::Naf::MachineRunnerInvocation.where(machine_runner_id: @runner_id).map(&:uuid)
      files = []
      invocation_uuids.each do |uuid|
        if Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/runners/#{uuid}/*"].present?
          files += Dir["#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/runners/#{uuid}/*"]
        end
      end

      if files.present?
        @read_from_s3 = false
        # Sort log files based on time
        return files.sort { |x, y| Time.parse(y.scan(::Logical::Naf::LogParser::Base::DATE_REGEX)[0][0]) <=> Time.parse(x.scan(::Logical::Naf::LogParser::Base::DATE_REGEX)[0][0]) }
      else
        get_s3_files do
          @read_from_s3 = true
          @s3_log_reader = ::Logical::Naf::LogReader.new
          s3_log_reader.runner_log_files.each do |file|
            if invocation_uuids.include?(file.scan(UUID_REGEX).first)
              files << file
            end
          end

          return files
        end
      end
    end

    def get_s3_files
      begin
        yield
      rescue
        logger.info 'AWS S3 Access Denied. Please check your permissions.'
        return []
      end
    end

    def get_json_from_log_file(file)
      if read_from_s3 == true
        @s3_log_reader.retrieve_file(file)
      else
        File.new(file, 'r')
      end
    end

    def sort_jsons
      # Sort log lines based on timestamp
      @jsons = jsons.sort { |x, y| x['line_number'] <=> y['line_number'] }
    end

    def insert_log_line(elem)
      if @job_id
        "#{elem['line_number']} #{elem['output_time']}: #{elem['message']}"
      elsif @runner_id
        "#{elem['output_time']} invocation(#{elem['id']}): #{elem['message']}"
      end
    end

    def get_invocation_id(uuid)
      ::Naf::MachineRunnerInvocation.find_by_uuid(uuid).id
    end


  end
end
