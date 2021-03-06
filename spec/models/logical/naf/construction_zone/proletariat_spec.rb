require 'spec_helper'

module Logical::Naf::ConstructionZone

  describe Proletariat do

  	let!(:proletariat) { ::Logical::Naf::ConstructionZone::Proletariat.new }
  	let(:application) { FactoryGirl.create(:scheduled_application) }
  	let(:application_type) { FactoryGirl.create(:rails_app_type) }
  	let(:restriction) { FactoryGirl.create(:no_limit) }
  	let!(:params) {
      {
        command: '::Process::Naf::Janitor.run',
        application_type_id: application_type.id,
        application_run_group_restriction_id: restriction.id,
        application_run_group_name: '::Process::Naf::Janitor.run',
        application_run_group_limit: 1,
        priority: 0,
        application_id: application.id,
        application_schedule_id: application.application_schedules.first.id
      }
  	}
		let!(:affinity) { { affinity_id: FactoryGirl.create(:normal_affinity).id } }
		let!(:prerequisite) { FactoryGirl.create(:job) }

  	describe '#create_job' do
  		it 'return a historical job' do
  			proletariat.create_job(params, [], []).should be_a(::Naf::HistoricalJob)
  		end
  	end

  	describe '#create_historical_job' do
  		let!(:historical_job) { proletariat.create_historical_job(params, [affinity], [prerequisite]) }

  		it 'return historical job when exception is not raised' do
  			historical_job.should be_a(::Naf::HistoricalJob)
  		end

  		it 'create a historical job affinity tab' do
  			::Naf::HistoricalJobAffinityTab.should have(1).records
  		end

  		it 'create a historical job affinity tab' do
  			::Naf::HistoricalJobPrerequisite.should have(1).records
  		end

  		it 'raise an exception when there is a loop found in prerequisites' do
  			prerequisite.should_receive(:prerequisites).and_raise(::Naf::HistoricalJob::JobPrerequisiteLoop.new(prerequisite))
  			begin
  				job = proletariat.create_historical_job(params, [affinity], [prerequisite])
  			rescue
  			end
  			job.should be_nil
  		end
  	end

  	describe '#create_queued_job' do
  		let!(:historical_job) { FactoryGirl.create(:scheduled_job) }

  		it 'return a queued job' do
  			historical_job.application_schedule_id = historical_job.application.application_schedules.first.id
  			proletariat.create_queued_job(historical_job).should be_a(::Naf::QueuedJob)
  		end
  	end
  end

end
