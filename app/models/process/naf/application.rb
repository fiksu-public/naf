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

    def database_application_name
      return "#{af_name}(pid: #{Process.pid}, nid: #{@naf_job_id})"
    end

    def log4r_pattern_formatter_format
      return "#{@log_with_timestamps ? '%d ' : ''}%C[#{@naf_job_id}] %l %M"
    end

    def update_job_status
      if @naf_job_id.is_a?(Integer) && @naf_job_id > 0
        job = ::Naf::Job.find_by_id(@naf_job_id)
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
              begin
                log_level_hash = JSON.parse(@last_log_level)
              rescue StandardError => e
                logger.error "couldn't parse job.log_level: #{@last_log_level}: (#{e.message})"
                log_level_hash = {}
              end
              set_logger_levels(log_level_hash)
            end
          end
        end
      end
    end

    def work
    end
  end
end
