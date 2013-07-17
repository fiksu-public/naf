module Logical
  module Naf
    class JobFetcher
      include ::Af::Application::SafeProxy

      attr_reader :machine

      def initialize(machine)
        @machine = machine
      end

      def fetch_next_job
        fetch_possible_jobs.each do |possible_job|
          running_job = nil
          ::Naf::HistoricalJob.lock_for_job_queue do
            running_job = start_job(possible_job)
          end

          if running_job.present?
            # found a job
            parse_log_level(running_job)

            return running_job
          end
        end

        # no jobs found
        return nil
      end

      private

      # This method fetches queued jobs that can be started. In order for a job to
      # run on a machine, we need to check affinities for historical_job_affinity_tabs
      # and machine_affinity_slots.
      #
      # A job without affinity tabs can be run on any machine
      # A job with affinity tabs can only run on machines:
      #   - that have matching affinity slot(s)
      #   - don't have any affinity slots
      #
      # A machine without affinity slots can run any jobs
      # A machine with non-required affinity slots can run jobs:
      #   - that don't have any affinity tabs
      #   - that have affinity tab(s) that match affinity slot(s)
      # A machine with required affinity slots can run jobs:
      #   - that have affinity tab(s) that match the required affinity slot(s)
      #     and if other affinity tabs are present, they also need to match
      #     afffinity slots
      #
      def fetch_possible_jobs
        possible_jobs = nil
        if machine.machine_affinity_slots.select(&:required).present?
          # Retrieve the machine's required affinities in order to not
          # compute it several times.
          required_machine_affinities = ::Naf::Machine.
            select("ARRAY(
              SELECT affinity_id
              FROM naf.machine_affinity_slots
              WHERE machine_id = #{machine.id} AND required = true
              ORDER BY affinity_id) AS required_affinities").
            group("required_affinities").
            first.required_affinities

          # Retrieve queued jobs that have the required affinity/affinities
          job_ids = ::Naf::QueuedJob.
            group(:id).
            having("array(
              select affinity_id::integer
              from naf.historical_job_affinity_tabs
              where historical_job_id = queued_jobs.id and affinity_id in (
               select affinity_id
               from naf.machine_affinity_slots
               where machine_id = #{machine.id} and required = true)
              order by affinity_id) = '#{required_machine_affinities}'").
            limit(100).pluck(:id)

          # Choose queued jobs that can be run by the machine
          possible_jobs = ::Naf::QueuedJob.
            where("id IN (?)", job_ids).
            runnable_by_machine(machine).
            exclude_run_group_names(run_group_names_above_limit).
            prerequisites_finished.
            order_by_priority.limit(100)
        elsif machine.machine_affinity_slots.present?
          # Choose queued jobs that can be run by the machine
          possible_jobs = ::Naf::QueuedJob.
            runnable_by_machine(machine).
            exclude_run_group_names(run_group_names_above_limit).
            prerequisites_finished.
            order_by_priority.limit(100)
        else
          # Machine can run any queued job
          possible_jobs = ::Naf::QueuedJob.
            exclude_run_group_names(run_group_names_above_limit).
            prerequisites_finished.
            order_by_priority.limit(100)
        end
      end

      # This method finds the group names that reached its limit and exclude them
      # when fetching queued jobs
      def run_group_names_above_limit
        running_groups = ::Naf::RunningJob.
          select("application_run_group_name, application_run_group_limit, count(*)").
          group("application_run_group_name, application_run_group_limit")
        queued_groups = ::Naf::QueuedJob.
          select("application_run_group_name, application_run_group_limit, count(*)").
          group("application_run_group_name, application_run_group_limit")

        running_group_names_and_limits = {}
        running_groups.each do |group|
          if group.present? && group.application_run_group_name.present?
            running_group_names_and_limits[group.application_run_group_name.to_sym] = [group.application_run_group_limit, group.count.to_i]
          end
        end
        queued_group_names_and_limits = {}
        queued_groups.each do |group|
          if group.present? && group.application_run_group_name.present?
            queued_group_names_and_limits[group.application_run_group_name.to_sym] = [group.application_run_group_limit, group.count.to_i]
          end
        end

        names_excluded = []
        running_group_names_and_limits.each do |key, values|
          # Run group name present in QueuedJobs
          if queued_group_names_and_limits[key].present?
            # Check run group limit and number of running jobs in the group
            if queued_group_names_and_limits[key][0] <= values[1]
              names_excluded << key
            end
          end
        end

        names_excluded
      end

      def start_job(possible_job)
        sql = <<-SQL
          UPDATE
            #{::Naf::HistoricalJob.partition_table_name(possible_job.id)}
          SET
            started_at = NOW(),
            started_on_machine_id = ?
          WHERE
            id = ? AND started_at IS NULL
          RETURNING
            *
        SQL

        historical_job = ::Naf::HistoricalJob.find_by_sql([sql, machine.id, possible_job.id]).first
        if historical_job.present?
          ::Naf::QueuedJob.delete(historical_job.id)
          running_job = ::Naf::RunningJob.new(application_id: historical_job.application_id,
                                              application_type_id: historical_job.application_type_id,
                                              command: historical_job.command,
                                              application_run_group_restriction_id: historical_job.application_run_group_restriction_id,
                                              application_run_group_name: historical_job.application_run_group_name,
                                              application_run_group_limit: historical_job.application_run_group_limit,
                                              started_on_machine_id: historical_job.started_on_machine_id,
                                              started_at: historical_job.started_at,
                                              log_level: historical_job.log_level)
          running_job.id = historical_job.id
          running_job.save!

          running_job
        else
          nil
        end
      end

      def logger
        return af_logger(self.class.name)
      end

      def parse_log_level(running_job)
        log_levels = {}
        unless machine.log_level.blank?
          begin
            log_level_hash = JSON.parse(machine.log_level)
            log_levels.merge!(log_level_hash)
          rescue StandardError => e
            logger.error "couldn't parse machine.log_level: #{machine.log_level}: (#{e.message})"
          end
        end

        unless running_job.application.nil? || running_job.application.log_level.blank?
          begin
            log_level_hash = JSON.parse(running_job.application.log_level)
            log_levels.merge!(log_level_hash)
          rescue StandardError => e
            logger.error "couldn't parse running_job.application.log_level: #{running_job.application.log_level}: (#{e.message})"
          end
        end

        running_job.log_level = log_levels.to_json
        running_job.save!
      end

    end
  end
end
