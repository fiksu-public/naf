require 'statsd'

module Logical
  module Naf
    class MetricSender

      attr_reader :statsd,
                  :machine,
                  :metric_send_delay

      attr_accessor :last_sent_metrics

      def initialize(metric_send_delay, machine)
        @metric_send_delay = metric_send_delay
        @statsd = Statsd.new
        @last_sent_metrics = nil
        @machine = machine
      end

      # Instance methods

      def send_metrics
        if last_sent_metrics.nil? || (Time.zone.now - last_sent_metrics) > metric_send_delay.seconds
          running_job_count = ::Naf::HistoricalJob.where(
                  "(started_at IS NOT NULL AND finished_at IS NULL AND " +
                  "started_on_machine_id = ?)",
                  machine.id).count +
                  ::Naf::HistoricalJob.where(
                  "(started_at IS NOT NULL AND finished_at > ? AND " +
                  "started_on_machine_id = ?)",
                  Time.zone.now - metric_send_delay.seconds, machine.id).count
          terminating_job_count = ::Naf::HistoricalJob.where(
                  "(finished_at IS NULL AND request_to_terminate = true AND " +
                  "started_on_machine_id = ?)",
                  machine.id).count
          long_terminating_job_count = ::Naf::HistoricalJob.where(
                  "(finished_at IS NULL AND request_to_terminate = true AND " +
                  "updated_at < ? AND started_on_machine_id = ?)",
                  Time.zone.now - 30.minutes, machine.id).count
          recent_errored_job_count = ::Naf::HistoricalJob.where(
                  "(finished_at IS NOT NULL AND exit_status > 0 AND " +
                  "finished_at > ? AND request_to_terminate = false " +
                  "AND started_on_machine_id = ?)",
                  Time.zone.now - metric_send_delay.seconds, machine.id).count

          statsd.gauge("naf.runner.alive",
              1, tags: ::Naf.configuration.metric_tags)
          statsd.gauge("naf.jobs.running",
              running_job_count, tags: ::Naf.configuration.metric_tags)
          statsd.gauge("naf.jobs.terminating",
              terminating_job_count, tags: ::Naf.configuration.metric_tags)
          statsd.gauge("naf.jobs.terminating-long",
              long_terminating_job_count, tags: ::Naf.configuration.metric_tags)
          statsd.gauge("naf.jobs.recent-errored",
              recent_errored_job_count, tags: ::Naf.configuration.metric_tags)
          last_sent_metrics = Time.zone.now
        end
      end
      
    end
  end
end
