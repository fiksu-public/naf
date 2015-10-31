require 'spec_helper'

module Logical::Naf::ConstructionZone
  describe Foreman do
    let!(:foreman) { Logical::Naf::ConstructionZone::Foreman.new }
    let!(:work_order) {
      Logical::Naf::ConstructionZone::WorkOrder.new('::Process::Naf::Janitor.run')
    }

    describe '#enqueue' do
      it 'return historical job when enqueue_backlogs is set to true' do
        work_order.enqueue_backlogs
        expect(foreman.enqueue(work_order)).to be_a(::Naf::HistoricalJob)
      end

      it 'return historical job when enqueue_backlogs is set to false and there is not run group limit' do
        expect(foreman.enqueue(work_order)).to be_a(::Naf::HistoricalJob)
      end

      it 'return nil when work order is limited by run group' do
        expect(foreman).to receive(:limited_by_run_group?).and_return(true)
        expect(foreman.enqueue(work_order)).to be_nil
      end
    end

    describe '#limited_by_run_group?' do
      let!(:no_limit) { FactoryGirl.create(:no_limit) }
      let!(:limited_per_machine) { FactoryGirl.create(:limited_per_machine) }
      let!(:limited_per_all_machines) { FactoryGirl.create(:limited_per_all_machines) }

      it 'return false when run group restriction is set to no limit' do
        expect(foreman.limited_by_run_group?(no_limit, nil, nil, [])).to be_falsey
      end

      it 'return false when run group limit is nil' do
        expect(foreman.limited_by_run_group?(limited_per_machine, 'test', nil, [])).to be_falsey
      end

      it 'return false when run group name is nil' do
        expect(foreman.limited_by_run_group?(limited_per_machine, nil, 1, [])).to be_falsey
      end

      describe 'run group restriction is set to limited per machine' do
        let!(:machine) { factory_girl_machine() }
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
          expect(foreman.limited_by_run_group?(limited_per_machine, 'test', 1, [])).to be_falsey
        end

        it 'return false when limit is greater than number of running/queued jobs' do
          expect(foreman.limited_by_run_group?(
            limited_per_machine, 'test', 5, [{ affinity_id: tab.affinity.id }]
          )).to be_falsey
        end

        it 'return true when limit is equal to number of running/queued jobs' do
          expect(foreman.limited_by_run_group?(
            limited_per_machine, 'test', 1, [{ affinity_id: tab.affinity.id }]
          )).to be_truthy
        end

        it 'return true when limit is less than number of running/queued jobs' do
          FactoryGirl.create(:running_job_base, application_run_group_name: 'test',
                                                started_on_machine_id: machine.id)
          expect(foreman.limited_by_run_group?(
            limited_per_machine, 'test', 1, [{ affinity_id: tab.affinity.id }]
          )).to be_truthy
        end
      end

      describe 'run group restriction is set to limited per all machines' do
        it 'return false when limit is greater than number of running/queued jobs' do
          expect(foreman.limited_by_run_group?(limited_per_all_machines, 'test', 1, [])).to be_falsey
        end

        it 'return true when limit is equal to number of running/queued jobs' do
          FactoryGirl.create(:queued_job, application_run_group_name: 'test')
          expect(foreman.limited_by_run_group?(limited_per_all_machines, 'test', 1, [])).to be_truthy
        end

        it 'return true when limit is less than number of running/queued jobs' do
          FactoryGirl.create(:queued_job, application_run_group_name: 'test')
          FactoryGirl.create(:running_job_base, application_run_group_name: 'test')
          expect(foreman.limited_by_run_group?(limited_per_all_machines, 'test', 1, [])).to be_truthy
        end
      end

      it 'return true when a different run group restriction is found' do
        restriction = FactoryGirl.create(:run_group_restriction)
        expect(foreman.limited_by_run_group?(restriction, 'test', 1, [])).to be_truthy
      end
    end
  end
end
