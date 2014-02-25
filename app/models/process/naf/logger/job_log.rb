module Process::Naf::Logger
  class JobLog < Base

    opt :job_id, type: :int

    def file_path
      "#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/jobs/#{@job_id}/"
    end

  end
end
