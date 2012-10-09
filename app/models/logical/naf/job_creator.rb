module Logical
  module Naf
    class JobCreator
      def queue_rails_job(command,
                          application_run_group_restriction = ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
                          application_run_group_name = :command,
                          application_run_group_limit = 1,
                          priority = 0,
                          affinities = [],
                          prerequisites = [])
        application_run_group_name = command if application_run_group_name == :command
        ::Naf::Job.transaction do
          job = ::Naf::Job.create(:application_type_id => 1,
                                  :command => command,
                                  :application_run_group_restriction_id => application_run_group_restriction.id,
                                  :application_run_group_name => application_run_group_name,
                                  :application_run_group_limit => application_run_group_limit,
                                  :priority => priority)
          affinities.each do |affinity|
            ::Naf::JobAffinityTab.create(:job_id => job.id, :affinity_id => affinity.id)
          end
          job.verify_prerequisites(prerequisites)
          prerequisites.each do |prerequisite|
            ::Naf::JobPrerequisite.create(:job_id => job.id,
                                          :job_created_id => job.created_at,
                                          :prerequisite_job_id => prerequisite.id)
          end
          return job
        end
      end

      def queue_application(application,
                            application_run_group_restriction,
                            application_run_group_name,
                            application_run_group_limit = 1,
                            priority = 0,
                            affinities = [])
        ::Naf::Job.transaction do
          job = ::Naf::Job.create(:application_id => application.id,
                                  :application_type_id => application.application_type_id,
                                  :command => application.command,
                                  :application_run_group_restriction_id => application_run_group_restriction.id,
                                  :application_run_group_name => application_run_group_name,
                                  :application_run_group_limit => application_run_group_limit,
                                  :priority => priority)
          affinities.each do |affinity|
            ::Naf::JobAffinityTab.create(:job_id => job.id, :affinity_id => affinity.id)
          end
          # XXX check prerequisites
          return job
        end
      end

      def queue_application_schedule(application_schedule)
        return queue_application(application_schedule.application,
                                 application_schedule.application_run_group_restriction,
                                 application_schedule.application_run_group_name,
                                 application_schedule.application_run_group_limit,
                                 application_schedule.priority,
                                 application_schedule.affinities)
      end
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

    MiddleClass = JobCreator
  end
end
