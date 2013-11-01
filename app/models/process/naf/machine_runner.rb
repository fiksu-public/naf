require 'open4'

module Process::Naf
  class MachineRunner < ::Process::Naf::Application

  	LOG_MAX_SIZE = 10_000

    attr_accessor :runner,
                  :invocation,
                  :line_number,
                  :file_line_number

  	def work
      # Track the number of logs
      @line_number = 1
      @file_line_number = 1

      set_runner
      invocation_count = 0
      if runner.present? && runner.machine_runner_invocations.present?
        invocation_count = runner.machine_runner_invocations.count
      end

      # fork and run
    	pid, stdin, stdout, stderr = Open4::popen4(::Naf::ApplicationType::SCRIPT_RUNNER + " ::Process::Naf::Runner.run")
    	stdin.close

      check_runner(invocation_count)

    	while true
      	write_logs(stdout, stderr)
        break if invocation.reload.status == 'dead'
      end
  	end

  	private

  	def write_logs(stdout, stderr)
      # Each log file path is unique
      log_file = create_log_file

      # Continue reading logs from stdout/stderror until it reaches end of file
      while true
        read_pipes = []
        read_pipes << stdout if stdout
        read_pipes << stderr if stderr
        return if (read_pipes.length == 0)

        error_pipes = read_pipes.clone
        read_array, write_array, error_array = Kernel.select(read_pipes, nil, error_pipes, 1)

        unless error_array.blank?
          logger.error "runner(#{runner.id}): select returned error for #{error_pipes.inspect} (read_pipes: #{read_pipes.inspect})"
          # XXX we should probably close the errored FDs
        end

        unless read_array.blank?
          for r in read_array do
            log_lines = ""
            log_file = check_log(log_file, line_number)

            begin
              # Read from stdout in chunks
              logs = r.read_nonblock(10240).split("\n")
              # Parse each log line into JSON
              logs.each do |log|
                log_lines << JSON.pretty_generate({
                	invocation_id: invocation.id,
                  line_number: line_number,
                  output_time: Time.zone.now.strftime("%Y-%m-%d %H:%M:%S.%L"),
                  message: log.strip
                })
                @line_number += 1
              end
            rescue Errno::EAGAIN
            rescue Errno::EINTR
            rescue EOFError => eof
              stdout = nil if r == stdout
              stderr = nil if r == stderr
            else
              log_file.write(log_lines)
              # Since the file is buffered, we want to tell it to write in chunks.
              # Files should be shown as the scripts runs.
              log_file.flush
            end
          end
        end
      end

      log_file.close
    end

    def set_runner
      @runner ||= ::Naf::Machine.find_by_server_address(::Naf::Machine.machine_ip_address).machine_runners.last
    end

    def check_runner(invocation_count)
      while runner.blank?
        set_runner
        sleep 1
      end

      while runner.current_invocation.blank?
        set_runner
        sleep 1
      end

      while invocation_count == runner.machine_runner_invocations.count
        set_runner
        sleep 1
      end

      @invocation = runner.current_invocation
    end

    def create_log_file
      # Create the directory path if it doesn't exist
      unless File.directory?("#{::Naf::PREFIX_PATH}/runners/#{runner.id}/invocations/#{invocation.id}")
        FileUtils.mkdir_p("#{::Naf::PREFIX_PATH}/runners/#{runner.id}/invocations/#{invocation.id}")
      end

      file = Dir["#{::Naf::PREFIX_PATH}/runners/runner.id/invocations/invocation.id/#{file_line_number}_*"].first
      if file.blank?
        file = File.open("#{::Naf::PREFIX_PATH}/runners/#{runner.id}/invocations/#{invocation.id}/#{file_line_number}_#{Time.zone.now}.json", 'wb')
      end

      file
    end

    def check_log(file, line_number)
      # When a file gets too large, close it and continue writing to another file
      if file.size > LOG_MAX_SIZE
        @file_line_number = @line_number
        file.close
        file = File.open("#{::Naf::PREFIX_PATH}/runners/#{runner.id}/invocations/#{invocation.id}/#{file_line_number}_#{Time.zone.now}.json", 'wb')
      end

      file
    end

  end
end
