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
        ::Naf::Job.possible_jobs.select("*").select_affinity_ids.order_by_priority.each do |possible_job|
          job_affinity_ids = possible_job.affinity_ids[1..-2].split(',').map(&:to_i)

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
          unfinished_prerequisites = ::Naf::JobPrerequisite.from_partition(possible_job.created_at).where(:job_id => possible_job.id).reject do |job_prerequisite|
            job_prerequisite.prerequisite_job.finished_at.present?
          end
          next unless unfinished_prerequisites.blank?

          job = nil
          ::Naf::Job.lock_for_job_queue do
            limit = (possible_job.application_run_group_limit || 0)
            if possible_job.application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_machine.id
              if (::Naf::Job.recently_queued.started.not_finished.started_on(machine).in_run_group(possible_job.application_run_group_name).count + 1) > limit
                logger.debug "already running on this machine"
                next
              end
            elsif possible_job.application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines.id
              if (recently_queued.started.not_finished.in_run_group(possible_job.application_run_group_name).count + 1) > limit
                logger.debug "already running"
                next
              end
            else # possible_job.application_run_group_restriction.application_run_group_restriction_name == "no restrictions"
            end

            sql = <<-SQL
               UPDATE #{::Naf.schema_name}.jobs
                 SET
                     started_at = NOW(),
                     started_on_machine_id = ?
               WHERE
                 id = ? AND
                 started_at IS NULL
               RETURNING
                 *
            SQL

            job = ::Naf::Job.find_by_sql([sql, machine.id, possible_job.id]).first
          end

          if job.present?
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
            unless job.application.nil? || job.application.log_level.blank?
              begin
                log_level_hash = JSON.parse(job.application.log_level)
                log_levels.merge!(log_level_hash)
              rescue StandardError => e
                logger.error "couldn't parse job.application.log_level: #{job.application.log_level}: (#{e.message})"
              end
            end
            job.log_level = log_levels.to_json
            return job
          end
        end

        # no jobs found
        return nil
      end
    end
  end
end
