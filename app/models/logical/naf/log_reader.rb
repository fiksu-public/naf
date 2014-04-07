require 'aws'

module Logical
  module Naf
    class LogReader

      DATE_REGEX = /((\d){4}-(\d){2}-(\d){2} (\d){2}:(\d){2}:(\d){2} UTC)/

      def log_files
        tree = bucket.objects.with_prefix(job_log_prefix).as_tree
        directories = tree.children.select(&:branch?).collect(&:job_log_prefix).uniq

        files = []
        directories.each do |directory|
          tree = bucket.objects.with_prefix(directory).as_tree
          tree.children.select(&:leaf?).collect(&:key).each do |file|
            files << file
          end
        end
        return sort_files(files)
      end

      def runner_log_files
        tree = bucket.objects.with_prefix(runner_log_prefix).as_tree
        directories = tree.children.select(&:branch?).collect(&:runner_log_prefix).uniq

        files = []
        directories.each do |directory|
          tree = bucket.objects.with_prefix(directory).as_tree
          tree.children.select(&:leaf?).collect(&:key).each do |file|
            files << file
          end
        end
        return sort_files(files)
      end


      def retrieve_file(file)
        bucket.objects[file].read
      end

      def retrieve_job_files(job_id)
        return [] unless job_id.present?
        tree = bucket.objects.with_prefix(job_log_prefix + "#{job_id}").as_tree
        sort_files(tree.children.select(&:leaf?).collect(&:key))
      end

      private

      def s3
        # Use AWS credentials to access S3
        @s3 ||= AWS::S3.new(access_key_id: AWS_ID,
                            secret_access_key: AWS_KEY,
                            ssl_verify_peer: false)
      end

      def bucket
        @bucket ||= s3.buckets[NAF_BUCKET]
      end

      def runner_log_prefix
        @runner_log_prefix ||= "#{NAF_LOG_PATH}/#{creation_time}/#{::Naf::NAF_DATABASE_HOSTNAME}/#{::Naf::NAF_DATABASE}/#{::Naf.schema_name}/runners/"
      end

      def job_log_prefix
        @job_log_prefix ||= "#{NAF_LOG_PATH}/#{creation_time}/#{::Naf::NAF_DATABASE_HOSTNAME}/#{::Naf::NAF_DATABASE}/#{::Naf.schema_name}/jobs/"
      end

      def sort_files(files)
        files.sort do |x, y|
          -Time.parse(x.scan(/\d{8}_\d{4}/).last).to_i <=> -Time.parse(y.scan(/\d{8}_\d{4}/).last).to_i
        end
      end

    	def project_name
    		(`git remote -v`).slice(/\/\S+/).sub('.git','')[1..-1]
    	end

      def creation_time
      	::Naf::ApplicationType.first.created_at.strftime("%Y%m%d_%H%M%S")
      end

    end
  end
end
