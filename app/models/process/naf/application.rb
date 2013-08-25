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

    #----------------
    # *** Options ***
    #+++++++++++++++++

    opt :naf_job_id,
        "naf.historical_jobs.id for communication with scheduling system",
        env: "NAF_JOB_ID",
        type: :int
    opt :do_not_terminate,
        "refuse to terminate by job and machine IPC mechanics"

    def initialize
      super
      opt :log_configuration_files, default: ["af.yml",
                                              "af-#{Rails.env}.yml",
                                              "naf.yml",
                                              "naf-#{Rails.env}.yml",
                                              "nafjob.yml",
                                              "nafjob-#{Rails.env}.yml",
                                              "#{af_name}.yml",
                                              "#{af_name}-#{Rails.env}.yml"]
    end

    def database_application_name
      return "//pid=#{Process.pid}/jid=#{@naf_job_id}/#{af_name}"
    end

    def fetch_naf_job
      if @naf_job_id.is_a?(Integer) && @naf_job_id > 0
        return ::Naf::HistoricalJob.from_partition(@naf_job_id).find(@naf_job_id)
      end
      return nil
    end

    def post_command_line_parsing
      super
      Af::Logging::Configurator.log_ignore_configuration = (naf_job_id.blank? && Af::Logging::Configurator.log_console != false)
    end

    def pre_work
      set_connection_application_name(database_application_name)

      Log4r::GDC.set(naf_job_id.to_s)

      super

      update_job_status
    end

    def update_job_status
      periodic_application_checkpoint

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
            logging_configurator.parse_and_set_logger_levels(@last_log_level)
          end
        end
      end
    end

    def update_job_tags(old_tags, new_tags)
      job = fetch_naf_job
      if job
        job.remove_tags(old_tags.map(&:to_s))
        job.add_tags(new_tags.map(&:to_s))
      end
    end

    def add_jobs_tags(new_tags)
      update_job_tags({}, new_tags)
    end

    def remove_jobs_tags(old_tags)
      update_job_tags(old_tags, {})
    end

    def work
    end
  end
end
