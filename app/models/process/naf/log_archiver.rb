require 'aws'

module Process::Naf
  class LogArchiver < ::Process::Naf::Application

    NAF_JOBS_LOG_PATH = "#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/"
    NAF_RUNNERS_LOG_PATH = "#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/runners/"
    DATE_REGEX = /\d{8}_\d{6}/
    LOG_RETENTION = 1

  	def work
  		# Use AWS credentials to access S3
			s3 = AWS::S3.new(access_key_id: AWS_ID,
                       secret_access_key: AWS_KEY,
                       ssl_verify_peer: false)

			# Each project will have a specific bucket
			bucket = s3.buckets[NAF_BUCKET]
      files = log_files

      logger.info 'Starting to save files to s3...'
      files.each do |file|
        # Write file if not existent
        object = bucket.objects["#{NAF_LOG_PATH}/#{creation_time}" + file[12..-1]]
        if !object.exists?
          # Write file to S3
          result = object.write(File.open(file).read)
          logger.info "File #{file} saved to S3"
        end
      end

      logger.info 'Starting to archive files...'
      archive_old_files(files)
  	end

  	private

  	def project_name
  		(`git remote -v`).slice(/\/\S+/).sub('.git','')[1..-1]
  	end

    def log_files
      files = Dir[NAF_JOBS_LOG_PATH + "*/*"]
      files += Dir[NAF_RUNNERS_LOG_PATH + "*/*"]
      # Sort log files based on time
      files = files.sort { |x, y| Time.parse(y.scan(DATE_REGEX).first) <=> Time.parse(x.scan(DATE_REGEX).first) }

      today = Time.zone.now.to_date
      old_files = []
      files.each_with_index do |file, index|
        if (today - Time.parse(file.scan(DATE_REGEX).first).to_date).to_i > LOG_RETENTION
          old_files = files[index..-1]
          break
        end
      end

      return old_files
    end

    def creation_time
    	::Naf::ApplicationType.first.created_at.strftime("%Y%m%d_%H%M%S")
    end

    def archive_old_files(files)
      copy_files
      today = Time.zone.now.to_date
      files.each do |file|
        logger.info "Archived file: #{file}"
        `rm #{file}`
      end
    end

    def copy_files
      if File.directory?(Naf::LOGGING_ROOT_DIRECTORY + "/naf")
        # Each archive will have a unique path based on the time archived
        time = Time.zone.now.to_s
        FileUtils.mkdir_p(Naf::LOGGING_ROOT_DIRECTORY + Naf::LOGGING_ARCHIVE_DIRECTORY + "/#{time}")

        # Move the naf logs into the archive directory
        `cp -r #{Naf::LOGGING_ROOT_DIRECTORY}/naf #{Naf::LOGGING_ROOT_DIRECTORY + Naf::LOGGING_ARCHIVE_DIRECTORY}/#{time.gsub(' ', '\ ')}`
      end
    end

  end
end
