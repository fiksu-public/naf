require 'spec_helper'

module Logical
  module Naf
    describe JobCreator do

      let!(:job_creator) { ::Logical::Naf::JobCreator.new }
      let!(:historical_job) { FactoryGirl.create(:job) }
      let(:application) { FactoryGirl.create(:scheduled_application) }

      describe '#queue_application' do
        it 'not queue an application if the group limit is less than number of queued/running jobs' do
          historical_job.application_run_group_name = application.application_schedule.application_run_group_name
          historical_job.command = application.command
          historical_job.save!
          job_creator.create_queue_job(historical_job)

          job_creator.queue_application(application,
                                        application.application_schedule.application_run_group_restriction,
                                        application.application_schedule.application_run_group_name).should be_nil
        end

        it 'return a historical_job that has been queued' do
          job_creator.queue_application(application,
                                        application.application_schedule.application_run_group_restriction,
                                        application.application_schedule.application_run_group_name).should be_instance_of(::Naf::HistoricalJob)
        end

        it 'create affinity tabs when affinities are present' do
          job_creator.queue_application(application,
                                        application.application_schedule.application_run_group_restriction,
                                        application.application_schedule.application_run_group_name,
                                        1,
                                        0,
                                        [::Naf::Affinity.first])
          ::Naf::HistoricalJobAffinityTab.should have(1).records
        end
      end

      describe '#retrieve_jobs' do
        before do
          FactoryGirl.create(:queued_job, application_run_group_name: 'Test',
                                          application_run_group_limit: 1)
        end

        it 'return the correct records' do
          job_creator.retrieve_jobs(::Naf::QueuedJob, '::Naf::QueuedJob.test hello world', 'Test').
            count.to_i.should == 1
        end
      end

      describe '#queue_application_schedule' do
        it 'raise error if schedule has been queued' do
          expect { job_creator.queue_application_schedule(application.application_schedule, [application.application_schedule.id]) }.
            to raise_error(::Naf::HistoricalJob::JobPrerequisiteLoop)
        end

        it 'return a historical_job that has been queued' do
          job_creator.queue_application_schedule(application.application_schedule).should be_instance_of(::Naf::HistoricalJob)
        end
      end

      describe '#queue_rails_job' do
        it 'create and return a historical_job' do
          job = job_creator.queue_rails_job(:command)
          job.should be_instance_of(::Naf::HistoricalJob)
        end

        it 'create affinity tabs when affinites are present' do
          job_creator.queue_rails_job(:command,
                                      ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
                                      :command,
                                      1,
                                      0,
                                      [::Naf::Affinity.first])

          ::Naf::HistoricalJobAffinityTab.should have(1).records
        end
      end

      describe '#verify_and_create_prerequisites' do
        before do
          prereq_job = FactoryGirl.create(:job)
          job_creator.verify_and_create_prerequisites(historical_job, [prereq_job])
        end

        it 'insert a row correctly into naf.historical_job_prerequisites' do
          ::Naf::HistoricalJobPrerequisite.should have(1).records
        end
      end

      describe '#create_queue_job' do
        it 'insert a row correctly into naf.queued_jobs' do
          job_creator.create_queue_job(historical_job)
          ::Naf::QueuedJob.should have(1).records
        end
      end

    end

  end
end
