module Naf
  class ApplicationType < NafBase
    SCRIPT_RUNNER = "#{Rails.root}/script/rails runner"

    def spawn(job)
      self.send(invocation_method.to_sym, job)
    end

    def invoke(job, command)
      return Process.spawn({"NAF_APPLICATION_ID" => job.id}.merge(ENV), command)
    end

    def rails_invocator(job)
      return invoke(job, SCRIPT_RUNNER + " " + job.command)
    end

    def bash_command_invocator(job)
      return invoke(job, job.command)
    end

    def bash_script_invocator(job)
      return invoke(job, job.command)
    end

    def ruby_script_invocator(job)
      return invoke(job, job.command)
    end
  end
end
