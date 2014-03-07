require 'spec_helper'

module Logical::Naf::ConstructionZone

  describe Boss do
    let!(:boss) { Logical::Naf::ConstructionZone::Boss.new }
    let!(:work_order) {
      Logical::Naf::ConstructionZone::WorkOrder.new('::Process::Naf::Janitor.run')
    }
    let(:params) { {
      command: '::Process::Naf::Janitor.run',
      application_type: ::Naf::ApplicationType.rails,
      application_run_group_restriction: ::Naf::ApplicationRunGroupRestriction.
        limited_per_all_machines,
      application_run_group_name: '::Process::Naf::Janitor.run',
      application_run_group_limit: 1,
      priority: 0,
      affinities: [],
      prerequisites: [],
      enqueue_backlogs: false,
      application: nil,
      application_schedule: nil
    } }

    shared_examples 'create one historical job' do |num_records|
      it 'return the correct object' do
        job.should be_a(::Naf::HistoricalJob)
      end

      it 'return correct number of historical jobs' do
        ::Naf::HistoricalJob.should have(num_records).records
      end
    end

    describe '#enqueue_application' do
      let(:application) { FactoryGirl.create(:application) }
      let!(:job) {
        boss.enqueue_application(application,
                                 ::Naf::ApplicationRunGroupRestriction.no_limit,
                                 application.command)
      }

      it_should_behave_like 'create one historical job', 1
    end

    describe '#enqueue_application_schedule' do
      let!(:job) { boss.enqueue_application_schedule(FactoryGirl.create(:schedule)) }

      it_should_behave_like 'create one historical job', 1
    end

    describe '#enqueue_rails_command' do
      let!(:job) { boss.enqueue_rails_command('::Process::Naf::Janitor.run') }

      it_should_behave_like 'create one historical job', 1
    end

    describe '#enqueue_command' do
      let!(:job) { boss.enqueue_command('::Process::Naf::Janitor.run') }

      it_should_behave_like 'create one historical job', 1
    end

    describe '#enqueue_ad_hoc_command' do
      let!(:job) { boss.enqueue_ad_hoc_command(params) }

      it_should_behave_like 'create one historical job', 1
    end

    describe '#enqueue_n_commands_on_machines' do
      let!(:affinity) { FactoryGirl.create(:normal_affinity) }

      before do
        params[:application_run_group_quantum] = 2
        params[:application_run_group_limit] = 5
      end

      it 'not create a historical job when array of machines is empty' do
        boss.enqueue_n_commands_on_machines({})
        ::Naf::HistoricalJob.should have(0).records
      end

      it 'create two historical jobs when a machine is present' do
        machine = FactoryGirl.create(:machine)
        classification = FactoryGirl.create(:location_affinity_classification)
        FactoryGirl.create(:affinity, id: 5,
                                      affinity_name: machine.id.to_s,
                                      affinity_classification: classification)

        boss.enqueue_n_commands_on_machines(params, :from_limit, [machine])
        ::Naf::HistoricalJob.should have(2).records
      end
    end

    describe '#enqueue_n_commands' do
      subject { boss.enqueue_n_commands(params) }

      it 'create one historical jobs when application_run_group_quantum is not specified' do
        params[:application_run_group_quantum] = 1
        subject
        ::Naf::HistoricalJob.should have(1).records
      end

      it 'create five historical jobs' do
        params[:application_run_group_quantum] = 5
        params[:application_run_group_limit] = 5
        subject
        ::Naf::HistoricalJob.should have(5).records
      end
    end

    describe '#reenqueue' do
      let!(:job) { boss.reenqueue(FactoryGirl.create(:job)) }

      it_should_behave_like 'create one historical job', 2
    end
  end

end
