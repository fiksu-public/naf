module Logical
  module Naf
    class JobCreator
      def queue_application(application,
                            application_run_group_restriction,
                            application_run_group_name,
                            application_run_group_limit = 1,
                            priority = 0,
                            affinities = [],
                            prerequisites = [],
                            enqueue = false)

        # Before adding a job to the queue, check whether the number of
        # jobs (running/queued) is equal to or greater than the application
        # run group limit, or if enqueue_backlogs is set to false. If so,
        # do not add the job to the queue
        running_jobs = retrieve_jobs(::Naf::RunningJob, application.command, application_run_group_name)
        queued_jobs = retrieve_jobs(::Naf::QueuedJob, application.command, application_run_group_name)

        if enqueue == false && (running_jobs.present? || queued_jobs.present?)
          group_limit = running_jobs.try(:application_run_group_limit).to_i + queued_jobs.try(:application_run_group_limit).to_i
          total_jobs = running_jobs.try(:count).to_i + queued_jobs.try(:count).to_i

          return if group_limit <= total_jobs
        end

        ::Naf::HistoricalJob.transaction do
          historical_job = ::Naf::HistoricalJob.create!(application_id: application.id,
                                                        application_type_id: application.application_type_id,
                                                        command: application.command,
                                                        application_run_group_restriction_id: application_run_group_restriction.id,
                                                        application_run_group_name: application_run_group_name,
                                                        application_run_group_limit: application_run_group_limit,
                                                        priority: priority,
                                                        log_level: application.log_level)

          # Create historical job affinity tabs for each affinity associated with the historical job
          affinities.each do |affinity|
            affinity_parameter = ::Naf::ApplicationScheduleAffinityTab.
              where(affinity_id: affinity.id,
                    application_schedule_id: application.application_schedule.try(:id)).
              first.try(:affinity_parameter)
            ::Naf::HistoricalJobAffinityTab.create(historical_job_id: historical_job.id,
                                                   affinity_id: affinity.id,
                                                   affinity_parameter: affinity_parameter)
          end

          verify_and_create_prerequisites(historical_job, prerequisites)

          create_queue_job(historical_job)

          return historical_job
        end
      end

      def retrieve_jobs(klass, command, application_run_group_name)
        klass.select('application_run_group_limit, MAX(created_at) AS created_at, count(*)').
          where('command = ? AND application_run_group_name = ?', command, application_run_group_name).
          group('application_run_group_name, application_run_group_limit').first
      end

      def queue_application_schedule(application_schedule, schedules_queued_already = [])
        prerequisite_jobs = []

        # Check if schedule has been queued
        if schedules_queued_already.include? application_schedule.id
          raise ::Naf::HistoricalJob::JobPrerequisiteLoop.new(application_schedule)
        end

        # Keep track of queued schedules
        schedules_queued_already << application_schedule.id
        # Queue application schedule prerequisites
        application_schedule.prerequisites.each do |application_schedule_prerequisite|
          prerequisite_jobs << queue_application_schedule(application_schedule_prerequisite, schedules_queued_already)
        end

        # Queue the application
        return queue_application(application_schedule.application,
                                 application_schedule.application_run_group_restriction,
                                 application_schedule.application_run_group_name,
                                 application_schedule.application_run_group_limit,
                                 application_schedule.priority,
                                 application_schedule.affinities,
                                 prerequisite_jobs,
                                 application_schedule.enqueue_backlogs)
      end

      # This method act similar to queue_application but is used for testing purpose
      def queue_rails_job(command,
                          application_run_group_restriction = ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
                          application_run_group_name = :command,
                          application_run_group_limit = 1,
                          priority = 0,
                          affinities = [],
                          prerequisites = [])
        application_run_group_name = command if application_run_group_name == :command
        ::Naf::HistoricalJob.transaction do
          historical_job = ::Naf::HistoricalJob.create!(application_type_id: 1,
                                                        command: command,
                                                        application_run_group_restriction_id: application_run_group_restriction.id,
                                                        application_run_group_name: application_run_group_name,
                                                        application_run_group_limit: application_run_group_limit,
                                                        priority: priority)
          affinities.each do |affinity|
            ::Naf::HistoricalJobAffinityTab.create(historical_job_id: historical_job.id, affinity_id: affinity.id)
          end

          verify_and_create_prerequisites(historical_job, prerequisites)

          create_queue_job(historical_job)

          return historical_job
        end
      end

      def verify_and_create_prerequisites(job, prerequisites)
        job.verify_prerequisites(prerequisites)
        # Create historical job prerequisites for each prerequisite associated with the historical job
        prerequisites.each do |prerequisite|
          ::Naf::HistoricalJobPrerequisite.create(historical_job_id: job.id,
                                                  prerequisite_historical_job_id: prerequisite.id)
        end
      end

      def create_queue_job(historical_job)
        queued_job = ::Naf::QueuedJob.new(application_id: historical_job.application_id,
                                          application_type_id: historical_job.application_type_id,
                                          command: historical_job.command,
                                          application_run_group_restriction_id: historical_job.application_run_group_restriction_id,
                                          application_run_group_name: historical_job.application_run_group_name,
                                          application_run_group_limit: historical_job.application_run_group_limit,
                                          priority: historical_job.priority)
        queued_job.id = historical_job.id
        queued_job.save!
      end

      def queue_test
        queue_rails_job("#{self.class.name}.test")
      end

      def self.test(*foo)
        seconds = rand 120 + 15
        puts "TEST CALLED: #{Time.zone.now}: #{foo.inspect}: sleeping for #{seconds} seconds"
        sleep(seconds)
        puts "TEST DONE: #{Time.zone.now}: #{foo.inspect}"
      end
    end

    MiddleClass = JobCreator
  end
end
