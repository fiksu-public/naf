require 'spec_helper'

module Logical::Naf::ConstructionZone
  describe Foreman do

    before do
      FactoryGirl.create(:rails_app_type)
    end

    let!(:foreman) { Logical::Naf::ConstructionZone::Foreman.new }
    let!(:work_order) {
      Logical::Naf::ConstructionZone::WorkOrder.new('::Process::Naf::Janitor.run')
    }

    describe '#enqueue' do
      it 'return historical job when enqueue_backlogs is set to true' do
        work_order.enqueue_backlogs
        foreman.enqueue(work_order).should be_a(::Naf::HistoricalJob)
      end

      it 'return historical job when enqueue_backlogs is set to false and there is not run group limit' do
        foreman.enqueue(work_order).should be_a(::Naf::HistoricalJob)
      end

      it 'return nil when work order is limited by run group' do
        foreman.should_receive(:limited_by_run_group?).and_return(true)
        foreman.enqueue(work_order).should be_nil
      end
    end

    describe '#limited_by_run_group?' do
      let!(:no_limit) { FactoryGirl.create(:no_limit) }
      let!(:limited_per_machine) { FactoryGirl.create(:limited_per_machine) }
      let!(:limited_per_all_machines) { FactoryGirl.create(:limited_per_all_machines) }

      it 'return false when run group restriction is set to no limit' do
        foreman.limited_by_run_group?(no_limit, nil, nil, []).should be_false
      end

      it 'return false when run group limit is nil' do
        foreman.limited_by_run_group?(limited_per_machine, 'test', nil, []).should be_false
      end

      it 'return false when run group name is nil' do
        foreman.limited_by_run_group?(limited_per_machine, nil, 1, []).should be_false
      end

      describe 'run group restriction is set to limited per machine' do
        let!(:machine) { FactoryGirl.create(:machine) }
        let(:historical_job) { FactoryGirl.create(:job, application_run_group_name: 'test') }
        let!(:tab) { FactoryGirl.create(:machine_job_affinity_tab, historical_job_id: historical_job.id) }

        before do
          FactoryGirl.create(:queued_job, application_run_group_name: 'test',
                                          id: historical_job.id,
                                          historical_job: historical_job)
          FactoryGirl.create(:running_job_base, application_run_group_name: 'test',
                                                started_on_machine_id: machine.id,
                                                historical_job: historical_job,
                                                id: historical_job.id)
        end

        it 'return false when application does not have affinity associated with machine' do
          foreman.limited_by_run_group?(limited_per_machine, 'test', 1, []).should be_false
        end

        it 'return false when limit is greater than number of running/queued jobs' do
          foreman.limited_by_run_group?(
            limited_per_machine, 'test', 5, [{ affinity_id: tab.affinity.id }]
          ).should be_false
        end

        it 'return true when limit is equal to number of running/queued jobs' do
          foreman.limited_by_run_group?(
            limited_per_machine, 'test', 1, [{ affinity_id: tab.affinity.id }]
          ).should be_true
        end

        it 'return true when limit is less than number of running/queued jobs' do
          FactoryGirl.create(:running_job_base, application_run_group_name: 'test',
                                                started_on_machine_id: machine.id)
          foreman.limited_by_run_group?(
            limited_per_machine, 'test', 1, [{ affinity_id: tab.affinity.id }]
          ).should be_true
        end
      end

      describe 'run group restriction is set to limited per all machines' do
        it 'return false when limit is greater than number of running/queued jobs' do
          foreman.limited_by_run_group?(limited_per_all_machines, 'test', 1, []).should be_false
        end

        it 'return true when limit is equal to number of running/queued jobs' do
          FactoryGirl.create(:queued_job, application_run_group_name: 'test')
          foreman.limited_by_run_group?(limited_per_all_machines, 'test', 1, []).should be_true
        end

        it 'return true when limit is less than number of running/queued jobs' do
          FactoryGirl.create(:queued_job, application_run_group_name: 'test')
          FactoryGirl.create(:running_job_base, application_run_group_name: 'test')
          foreman.limited_by_run_group?(limited_per_all_machines, 'test', 1, []).should be_true
        end
      end

      it 'return true when a different run group restriction is found' do
        restriction = FactoryGirl.create(:run_group_restriction)
        foreman.limited_by_run_group?(restriction, 'test', 1, []).should be_true
      end
    end
  end
end
