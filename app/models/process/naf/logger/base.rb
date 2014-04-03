module Process::Naf::Logger
  class Base < ::Af::Application

    def work
      log_file = ::Logical::Naf::LogFile.new(file_path)
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
