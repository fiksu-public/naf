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
        expect(job).to be_a(::Naf::HistoricalJob)
      end

      it 'return correct number of historical jobs' do
        expect(::Naf::HistoricalJob.all.size).to eq(num_records)
      end
    end

    before do
      ::Naf::HistoricalJob.delete_all
      ::Naf::ApplicationType.all
      FactoryGirl.create(:rails_app_type)
    end

    describe '#enqueue_application' do
      let(:application) { FactoryGirl.create(:application) }
      let(:prereq) { FactoryGirl.create(:job) }
      let!(:job) {
        boss.enqueue_application(application,
                                 ::Naf::ApplicationRunGroupRestriction.no_limit,
                                 application.command,
                                 5,
                                 1,
                                 [::Naf::Affinity.first],
                                 [prereq],
                                 true)
      }

      it_should_behave_like 'create one historical job', 2

      it 'assign run group restriction correctly' do
        expect(job.application_run_group_restriction_id).to eq(::Naf::ApplicationRunGroupRestriction.no_limit.id)
      end

      it 'assign run group name correctly' do
        expect(job.application_run_group_name).to eq(application.command)
      end

      it 'assign run group limit correctly' do
        expect(job.application_run_group_limit).to eq(5)
      end

      it 'assign priority correctly' do
        expect(job.priority).to eq(1)
      end

      it 'assign affinities correctly' do
        expect(job.historical_job_affinity_tabs.map(&:affinity_id)).to eq([::Naf::Affinity.first.id])
      end

      it 'assign prerequisites correctly' do
        expect(job.historical_job_prerequisites.map(&:prerequisite_historical_job_id)).to eq([prereq.id])
      end

      it 'assign enqueue_backlogs correctly' do
        expect(job.application_run_group_name).to eq(application.command)
      end
    end

    describe '#enqueue_application_schedule' do
      let!(:schedule) { FactoryGirl.create(:schedule) }
      let!(:job) { boss.enqueue_application_schedule(schedule) }

      it_should_behave_like 'create one historical job', 1

      it 'create two historical jobs when schedule has a prerequisite' do
        schedule = FactoryGirl.create(:schedule)
        FactoryGirl.create(:schedule_prerequisite, application_schedule: schedule)
        boss.enqueue_application_schedule(schedule)

        expect(::Naf::HistoricalJob.all.size).to eq(3)
      end

      it 'assign application_schedule_id correctly' do
        expect(job.application_schedule_id).to eq(schedule.id)
      end
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
        expect(::Naf::HistoricalJob.all.size).to eq(0)
      end

      it 'create two historical jobs when a machine is present' do
        machine = FactoryGirl.create(:machine)
        classification = FactoryGirl.create(:machine_affinity_classification)
        FactoryGirl.create(:affinity, id: 5,
                                      affinity_name: machine.id.to_s,
                                      affinity_classification: classification)

        boss.enqueue_n_commands_on_machines(params, :from_limit, [machine])
        expect(::Naf::HistoricalJob.all.size).to eq(2)
      end
    end

    describe '#enqueue_n_commands' do
      subject { boss.enqueue_n_commands(params) }

      it 'create one historical jobs when application_run_group_quantum is not specified' do
        params[:application_run_group_quantum] = 1
        subject
        expect(::Naf::HistoricalJob.all.size).to eq(1)
      end

      it 'create five historical jobs' do
        params[:application_run_group_quantum] = 5
        params[:application_run_group_limit] = 5
        subject
        expect(::Naf::HistoricalJob.all.size).to eq(5)
      end
    end

    describe '#reenqueue' do
      let!(:job) { boss.reenqueue(FactoryGirl.create(:job)) }

      it_should_behave_like 'create one historical job', 2
    end
  end

end
