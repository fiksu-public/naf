module Logical::Naf::ConstructionZone
  class Proletariat
    def create_job(parameters, affinities, prerequisites)
      ::Naf::HistoricalJob.transaction do
        historical_job = create_historical_job(parameters, affinities, prerequisites)
        create_queued_job(historical_job)

        return historical_job
      end
    end

    def create_historical_job(parameters, affinities, prerequisites)
      ::Naf::HistoricalJob.transaction do
        historical_job = ::Naf::HistoricalJob.create!(parameters)
        # Create affinity tabs, if affinities are provided
        affinities.each do |affinity|
          ::Naf::HistoricalJobAffinityTab.create(affinity.merge(historical_job_id: historical_job.id))
        end
        # Verify there is no loop found in prerequisites
        historical_job.verify_prerequisites(prerequisites)
        # Create historical job prerequesites, if prerequisites are provided
        prerequisites.each do |prerequisite|
          ::Naf::HistoricalJobPrerequisite.create({
                                                    historical_job_id: historical_job.id,
                                                    prerequisite_historical_job_id: prerequisite.id
                                                  })
        end

        return historical_job
      end
    end

    def create_queued_job(historical_job)
      queued_job = ::Naf::QueuedJob.new(application_id: historical_job.application_id,
                                        application_schedule_id: historical_job.application_schedule_id,
                                        application_type_id: historical_job.application_type_id,
                                        command: historical_job.command,
                                        application_run_group_restriction_id: historical_job.application_run_group_restriction_id,
                                        application_run_group_name: historical_job.application_run_group_name,
                                        application_run_group_limit: historical_job.application_run_group_limit,
                                        priority: historical_job.priority)
      queued_job.id = historical_job.id
      queued_job.save!

      return queued_job
    end

  end
end
