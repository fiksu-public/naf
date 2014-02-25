module Process::Naf::Logger
  class RunnerLog < Base

    opt :invocation_uuid,
        "unique identifer used for runner logs",
        default: `uuidgen`

    def file_path
      "#{::Naf::PREFIX_PATH}/#{::Naf.schema_name}/runners/#{@invocation_uuid}/"
    end

  end
end
