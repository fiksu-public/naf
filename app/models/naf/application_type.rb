module Naf
  class ApplicationType < NafBase
    SCRIPT_RUNNER = "#{Rails.root}/script/rails runner"

    def execute(job)
      self.send(invocation_method.to_sym, job)
    end

    def rails_invocator(job)
      Process.exec(SCRIPT_RUNNER + " " + job.command)
    end

    def bash_command_invocator(job)
    end

    def bash_script_invocator(job)
    end

    def ruby_script_invocator(job)
    end
  end
end
