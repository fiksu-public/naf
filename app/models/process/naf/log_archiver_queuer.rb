module Process::Naf
  class LogArchiverQueuer < ::Process::Naf::Application

    def work
      # Archive logs
      params = { command: log_archiver.command }
      boss.enqueue_n_commands_on_machines(params, :from_limit, machines)
    end

    private

    def boss
      ::Logical::Naf::ConstructionZone::Boss.new
    end

    def machines
      ::Naf::Machine.enabled.up.all
    end

    def log_archiver
      ::Naf::Application.where(command: '::Process::Naf::LogArchiver.run').first
    end

  end
end
