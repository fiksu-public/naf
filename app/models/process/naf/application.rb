module Process::Naf
  class Application < ::Af::Application
    opt :naf_application_id, :env => "NAF_APPLICATION_ID", :type => :int, :default => "unknown"

    def log4r_name_suffix
      return ":[#{@naf_application_id}]"
    end

    def requested_to_terminate?
      if @naf_application_id.is_a? Integer && @naf_application_id > 0
        job = ::Naf::Job.find(@naf_application_id)
        if job
          if job.request_to_terminate
            return true
          end
          # if no machines row exist assume someone is running by hand (do not terminate)
          if job.machine && !job.machine.enabled
            return true
          end
        end
      end
      return false
    end

    def work
    end
  end
end
