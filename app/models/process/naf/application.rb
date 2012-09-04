module Process::Naf
  class Application < ::Af::Application
    class TerminationRequest < StandardError
      attr_reader :job, :reason
      def initialize(job, reason)
        @job = job
        @reason = reason
        super("Requested to terminate: #{reason}")
      end
    end

    opt :naf_job_id, "naf.jobs.id for communication with scheduling system", :env => "NAF_JOB_ID", :type => :int
    opt :do_not_terminate, "refuse to terminate by job and machine IPC mechanics"

    def initialize
      @last_log_level = nil
      super
    end

    def log4r_name_suffix
      return ":[#{@naf_job_id}]"
    end

    def update_job_status
      if @naf_job_id.is_a? Integer && @naf_job_id > 0
        job = ::Naf::Job.find(@naf_job_id)
        if job
          unless @do_not_terminate
            if job.request_to_terminate
              raise TerminationRequest.new(job, "job requested to terminate")
            end
            unless job.machine
              raise TerminationRequest.new(job, "machine not configured correctly")
            end
            unless job.machine.enabled
              raise TerminationRequest.new(job, "machine disabled")
            end
          end
          if job.log_level != @last_log_level
            @last_log_level = job.log_level
            set_logger_levels(@last_log_level || {})
          end
        end
      end
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
