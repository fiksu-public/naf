require 'spec_helper'

module Logical::Naf::ConstructionZone

  describe WorkOrder do
    let(:command) { '::Process::Naf::Janitor.run' }
    let!(:work_order) {
      ::Logical::Naf::ConstructionZone::WorkOrder.new(command)
    }

    describe '#historical_job_parameters' do
      let(:params) {
        {
          command: command,
          application_type_id: ::Naf::ApplicationType.rails.id,
          application_run_group_restriction_id: ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines.id,
          application_run_group_name: command,
          application_run_group_limit: 1,
          priority: 0,
          application_id: nil,
          application_schedule_id: nil
        }
      }

      it 'return correct values' do
        work_order.historical_job_parameters.should == params
      end
    end

    describe '#historical_job_affinity_tab_parameters' do
      it 'return hash with the affinity_id when a symbol is provided' do
        affinity = FactoryGirl.create(:affinity, id: 4, affinity_short_name: :small)
        work_order.instance_variable_set(:@affinities, [:small])
        work_order.historical_job_affinity_tab_parameters.
          should == [{ affinity_id: affinity.id }]
      end

      it 'raise an exception when there is not an object associated with the symbol' do
        work_order.instance_variable_set(:@affinities, [:small])
        expect { work_order.historical_job_affinity_tab_parameters }.
          to raise_error 'no affinity provided'
      end

      it 'return hash with the affinity_id when an Affinity object is provided' do
        affinity = ::Naf::Affinity.first
        work_order.instance_variable_set(:@affinities, [affinity])
        work_order.historical_job_affinity_tab_parameters.
          should == [{ affinity_id: affinity.id }]
      end

      it 'return hash with the affinity_id when a Machine object is provided' do
        machine = FactoryGirl.create(:machine)
        classification = FactoryGirl.create(:location_affinity_classification)
        affinity = FactoryGirl.create(:affinity, id: 4,
                                                 affinity_name: machine.id.to_s,
                                                 affinity_classification: classification)
        work_order.instance_variable_set(:@affinities, [machine])
        work_order.historical_job_affinity_tab_parameters.
          should == [{ affinity_id: affinity.id }]
      end

      it 'return nil when an ApplicationScheduleAffintyTab object is provided' do
        tab = FactoryGirl.build(:app_schedule_affinity_tab_base)
        work_order.instance_variable_set(:@affinities, [tab])
        work_order.historical_job_affinity_tab_parameters.should == [nil]
      end

      it 'return hash with the affinity_id when a Hash object is provided' do
        affinity = { affinity_id: 1 }
        work_order.instance_variable_set(:@affinities, [affinity])
        work_order.historical_job_affinity_tab_parameters.should == [affinity]
      end

      it 'raise an exception when a empty Hash object is provided' do
        work_order.instance_variable_set(:@affinities, [{}])
        expect { work_order.historical_job_affinity_tab_parameters }.
          to raise_error 'no affinity provided'
      end

      it 'raise an exception when a unknown object is provided' do
        work_order.instance_variable_set(:@affinities, [[]])
        expect { work_order.historical_job_affinity_tab_parameters }.
          to raise_error 'unknown affinity kind: []'
      end
    end

    describe '#historical_job_parameters' do
      it 'raise an exception when a non historical job is in prerequisites' do
        work_order.instance_variable_set(:@prerequisites, [1])
        expect { work_order.historical_job_prerequisite_historical_jobs }.
          to raise_error "found a non Naf::HistoricalJob in prerequisites: 1"
      end

      it 'not raise an exception when a historical job is in prerequisites' do
        historical_job = FactoryGirl.build(:job_base)
        work_order.instance_variable_set(:@prerequisites, [historical_job])
        work_order.historical_job_prerequisite_historical_jobs.should == [historical_job]
      end

      it 'not raise an exception when prerequisites is empty' do
        work_order.historical_job_prerequisite_historical_jobs.should == []
      end
    end

  end
end
