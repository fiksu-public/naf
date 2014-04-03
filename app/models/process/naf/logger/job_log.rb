module Process::Naf::Logger
  class JobLog < Base

    def file_path
      "#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{ENV['NAF_JOB_ID']}/"
    end

  end
end
