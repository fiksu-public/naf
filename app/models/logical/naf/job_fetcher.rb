module Logical
  module Naf
    class JobFetcher
      include ::Af::Application::SafeProxy

      attr_reader :machine

      def initialize(machine)
        @machine = machine
      end

      def logger
        return af_logger(self.class.name)
      end

      def fetch_next_job
        ::Naf::QueuedJob.order_by_priority.each do |possible_job|
          job_affinity_ids = possible_job.historical_job.affinity_ids

          # eliminate job if it can't run on this machine
          unless machine.machine_affinity_slots.select(&:required).all? { |slot| job_affinity_ids.include? slot.affinity_id }
            logger.debug "required affinity not found"
            next
          end

          machine_affinity_ids = machine.machine_affinity_slots.map(&:affinity_id)

          # eliminate job if machine can not run this it
          unless job_affinity_ids.all? { |job_affinity_id| machine.affinity_ids.include? job_affinity_id }
            logger.debug "machine does not meet affinity requirements"
            next
          end

          # check prerequisites
          next if ::Naf::HistoricalJobPrerequisite.from_partition(possible_job.id).where(historical_job_id: possible_job.id).any? do |job_prerequisite|
            ::Naf::HistoricalJob.from_partition(job_prerequisite.prerequisite_historical_job_id).
              find(job_prerequisite.prerequisite_historical_job_id).
              finished_at.nil?
          end

          running_job = fetch_running_job(possible_job)

          if running_job.present?
            # found a job
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

            return running_job
          end
        end

        # no jobs found
        return nil
      end

      private

      def fetch_running_job(possible_job)
        running_job = nil

        ::Naf::HistoricalJob.lock_for_job_queue do
          limit = (possible_job.application_run_group_limit || 0)

          if possible_job.application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_machine.id
            if (::Naf::RunningJob.started_on(machine).in_run_group(possible_job.application_run_group_name).count + 1) > limit
              logger.debug "already running on this machine"
              next
            end
          elsif possible_job.application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines.id
            if (::Naf::RunningJob.in_run_group(possible_job.application_run_group_name).count + 1) > limit
              logger.debug "already running"
              next
            end
          else # possible_job.application_run_group_restriction.application_run_group_restriction_name == "no restrictions"
          end

          sql = <<-SQL
             UPDATE
              #{::Naf::HistoricalJob.partition_table_name(possible_job.id)}
             SET
               started_at = NOW(),
               started_on_machine_id = ?
             WHERE
               id = ? AND
               started_at IS NULL
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
          end
        end

        running_job
      end

    end
  end
end
