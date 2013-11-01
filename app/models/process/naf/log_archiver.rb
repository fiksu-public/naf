require 'aws'

module Process::Naf
  class LogArchiver < ::Process::Naf::Application

    NAF_JOBS_LOG_PATH = "#{::Naf::PREFIX_PATH}/jobs/"
    NAF_RUNNERS_LOG_PATH = "#{::Naf::PREFIX_PATH}/runners/*/invocations/"
    DATE_REGEX = /((\d){4}-(\d){2}-(\d){2} (\d){2}:(\d){2}:(\d){2} UTC)/

  	def work
  		# Use AWS credentials to access S3
			s3 = AWS::S3.new(access_key_id: AWS_ID,
                       secret_access_key: AWS_KEY,
                       ssl_verify_peer: false)

			# Each project will have a specific bucket
			bucket = s3.buckets[NAF_BUCKET]

			log_files.each do |file|
				# Write file if not existent
				object = bucket.objects["naf/#{project_name}/#{Rails.env}/#{creation_time}" + file[12..-1]]
				if !object.exists?
					# Write file to S3
					result = object.write(File.open(file).read)
          logger.info "Result: #{result}"
				  logger.info "File #{file} saved to S3"
        end
			end
  	end

  	private

  	def project_name
  		(`git remote -v`).slice(/\/\S+/).sub('.git','')[1..-1]
  	end

    def log_files
      files = Dir[NAF_JOBS_LOG_PATH + "*/*"]
      files += Dir[NAF_RUNNERS_LOG_PATH + "*/*"]
      # Sort log files based on time
      files = files.sort { |x, y| Time.parse(y.scan(DATE_REGEX)[0][0]) <=> Time.parse(x.scan(DATE_REGEX)[0][0]) }

      return files
    end

    def creation_time
    	::Naf::ApplicationType.first.created_at.strftime("%Y%m%d_%H%M%S")
    end

  end
end
