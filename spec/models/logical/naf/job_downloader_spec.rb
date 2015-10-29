require 'spec_helper'

module Logical
  module Naf
    module LogParser
      describe JobDownloader do
        # Create a test file, making sure to not overwrite a current file.

        let!(:test_record_id) { 3 }
        let!(:test_file_path) { "#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{test_record_id}" }
        let!(:test_file_name) { "1_20140613_161535.json" }
        let!(:test_file_text) { "{\n" +
                                "  \"line_number\": 1,\n" +
                                "  \"output_time\": \"2014-06-13 16:15:35.689\",\n" +
                                "  \"message\": \"140613 12:15:35.689 pid=6020 jid=3 Process::Naf::LogArchiver INFO Starting to save files to s3...\"\n" +
                                "}" }
        let!(:test_file_output) { "1 2014-06-13 16:15:35.689: 140613 12:15:35.689 pid=6020 jid=3 Process::Naf::LogArchiver INFO Starting to save files to s3...\n" }
        let!(:segments_to_reset) { {} }
        let!(:file_preserved) { false }

        before() do
          # Create a file/directory for example log. If directory exists, move it and save it
          segments_to_reset = {}
          total_path = ""
          file_preserved = false

          test_file_path.split("/").each do |segment|
            unless segment == ""
              segments_to_reset[segment] = false
              unless File.exists?(total_path + segment + "/")
                Dir.mkdir(total_path + segment + "/")
                segments_to_reset[segment] = true
              end
              total_path += segment + "/"
            end
          end

          if File.exists?("#{test_file_path}/#{test_file_name}")
            FileUtils.mv("#{test_file_path}/#{test_file_name}", "#{test_file_path}/#{test_file_name}-preserving")
            file_preserved = true
          end

          File.open("#{test_file_path}/#{test_file_name}", 'w') { |file| file.write(test_file_text) }
        end

        after() do
          # Delete the example log file. If a directory was saved before, move it back
          File.delete("#{test_file_path}/#{test_file_name}")

          if file_preserved
            FileUtils.mv("#{test_file_path}/#{test_file_name}-preserving", "#{test_file_path}/#{test_file_name}")
          end

          current_path = test_file_path
          test_file_path.split("/").reverse_each do |segment|
            if segments_to_reset[segment]
              Dir.rmdir(current_path)
              current_path = current_path[0..-(segment.size + 2)]
            end
          end

        end

        it "returns the correct log" do
          job_log_downloader = JobDownloader.new({ 'record_id' => test_record_id })
          expect(job_log_downloader.logs_for_download).to eql(test_file_output)
        end

      end
    end
  end
end
