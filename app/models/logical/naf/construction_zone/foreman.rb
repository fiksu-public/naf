module Logical::Naf::ConstructionZone
  class Foreman
    include ::Af::Application::Component
    create_proxy_logger

    def initialize()
      @proletariat = Proletariat.new
    end

    def enqueue(work_order)
      unless work_order.enqueue_backlogs
        if limited_by_run_group?(work_order.application_run_group_restriction,
                                 work_order.application_run_group_name,
                                 work_order.application_run_group_limit,
                                 work_order.historical_job_affinity_tab_parameters)
          logger.warn "work order limited by run queue limits #{work_order.inspect}"
          return nil
        end
      end
      @proletariat.create_job(work_order.historical_job_parameters,
                              work_order.historical_job_affinity_tab_parameters,
                              work_order.historical_job_prerequisite_historical_jobs)
    end

    def limited_by_run_group?(application_run_group_restriction, application_run_group_name, application_run_group_limit, affinities)
      if (application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.no_limit.id ||
          application_run_group_limit.nil? ||
          application_run_group_name.nil?)
        false
      elsif application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_machine.id
        # Retrieve the affinity associated to the machine
        machine_affinity = nil
        affinities.each do |affinity|
          machine_affinity = ::Naf::Affinity.find_by_id(affinity[:affinity_id])
          if machine_affinity.affinity_classification_name == 'machine'
            break
          end
        end

        # If affinity is present, check if the sum of jobs running on the machine
        # and queued for the machine is less the application_run_group_limit.
        # If affinity is not present, send a log warning the user that application schedule
        # should have affinity associated to the machine in order to behave correctly, and
        # queue the application.
        if machine_affinity.present?
          queued_jobs = ::Naf::QueuedJob.
            joins(:historical_job).
            joins("INNER JOIN #{Naf.schema_name}.historical_job_affinity_tabs AS hjat
              ON hjat.historical_job_id = #{Naf.schema_name}.historical_jobs.id").
            where("#{Naf.schema_name}.historical_jobs.application_run_group_name = ? AND hjat.affinity_id = ?",
              application_run_group_name, machine_affinity.id).count
          running_jobs = ::Naf::RunningJob.where(
              application_run_group_name: application_run_group_name,
              started_on_machine_id: machine_affinity.affinity_name
            ).count

          queued_jobs + running_jobs >= application_run_group_limit
        else
          logger.warn "application schedule does not have affinity associated with a machine"
          false
        end
      elsif application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines.id
        (::Naf::QueuedJob.where(application_run_group_name: application_run_group_name).count +
         ::Naf::RunningJob.where(application_run_group_name: application_run_group_name).count) >= application_run_group_limit
      else
        logger.warn "not limited by run group restriction but don't know why: #{application_run_group_restriction.inspect}"
        true
      end
    end
  end
end
