require 'open4'

module Process::Naf
  class MachineRunner < ::Af::Application

    opt :invocation_uuid,
        "unique identifer used for runner logs",
        default: `uuidgen`

    def work
      log_file = ::Logical::Naf::LogFile.new("#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/runners/#{@invocation_uuid}/")
      log_file.open

      while $stdin.gets
        begin
          log_file << $_.rstrip
        ensure
          log_file.write
        end
      end

      log_file.close
    end

  end
end
