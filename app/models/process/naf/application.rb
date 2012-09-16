require 'log4r/formatter/patternformatter'

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
      super
      update_opts :log_configuration_files, :default => ["af.yml", "naf.yml", "nafjob.yml", "#{af_name}.yml"]
    end

    def database_application_name
      return "//pid=#{Process.pid}/jid=#{@naf_job_id}/#{af_name}"
    end

    def fetch_naf_job
      if @naf_job_id.is_a?(Integer) && @naf_job_id > 0
        return ::Naf::Job.find_by_id(@naf_job_id)
      end
      return nil
    end

    def pre_work
      set_connection_application_name(database_application_name)
      Log4r::GDC.set(naf_job_id.to_s)

      super

      update_job_status
    end

    def update_job_status
      job = fetch_naf_job
      if job
        unless @do_not_terminate
          if job.request_to_terminate
            logger.alarm "terminating by request"
            raise TerminationRequest.new(job, "job requested to terminate")
          end
          unless job.started_on_machine
            logger.alarm "terminating: #{job.started_on_machine} is misconfigured"
            raise TerminationRequest.new(job, "machine not configured correctly")
          end
          unless job.started_on_machine.enabled
            logger.alarm "terminating: #{job.started_on_machine} is disabled"
            raise TerminationRequest.new(job, "machine disabled")
          end
          if job.started_on_machine.marked_down
            logger.alarm "terminating: #{job.started_on_machine} is marked down"
            raise TerminationRequest.new(job, "machine marked down")
          end
        end
        if job.log_level != @last_log_level
          @last_log_level = job.log_level
          unless @last_log_level.blank?
            parse_and_set_logger_levels(@last_log_level)
          end
        end
      end
    end

    def work
    end
  end
end
