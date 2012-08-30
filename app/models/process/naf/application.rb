module Process::Naf
  class Application < ::Af::Application
    opt :naf_job_id, "naf.jobs.id for communication with scheduling system", :env => "NAF_JOB_ID", :type => :int

    def log4r_name_suffix
      return ":[#{@naf_job_id}]"
    end

    def requested_to_terminate?
      if @naf_job_id.is_a? Integer && @naf_job_id > 0
        job = ::Naf::Job.find(@naf_job_id)
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

    def pre_work
      super
      ActiveRecord::ConnectionAdapters::ConnectionPool.
        initialize_connection_application_name("#{self.class.name}(pid: #{Process.pid}, naf_job_id: #{@naf_job_id})")
    end

    def work
    end
  end
end
