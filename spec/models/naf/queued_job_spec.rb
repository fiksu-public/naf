require 'spec_helper'

module Naf
  describe QueuedJob do
    # Mass-assignment
    [:application_id,
     :application_schedule_id,
     :application_type_id,
     :command,
     :application_run_group_restriction_id,
     :application_run_group_name,
     :application_run_group_limit,
     :priority].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at,
     :updated_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should belong_to(:historical_job) }
    it { should belong_to(:application) }
    it { should belong_to(:application_schedule) }
    it { should belong_to(:application_type) }
    it { should belong_to(:application_run_group_restriction) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_type_id) }
    it { should validate_presence_of(:command) }
    it { should validate_presence_of(:application_run_group_restriction_id) }
    it { should validate_presence_of(:priority) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#order_by_priority" do
      let!(:high_priority_job) { FactoryGirl.create(:queued_job, priority: 1) }
      let!(:low_priority_job) { FactoryGirl.create(:queued_job, priority: 2) }
      let!(:low_priority_job2) { FactoryGirl.create(:queued_job, priority: 2) }

      it "return records in correct order" do
        Naf::QueuedJob.order_by_priority.
          should == [high_priority_job, low_priority_job, low_priority_job2]
      end
    end

    describe "#exclude_run_group_names" do
      let!(:included_job) { FactoryGirl.create(:queued_job, application_run_group_name: 'test 1') }
      let!(:excluded_job) { FactoryGirl.create(:queued_job, application_run_group_name: 'test 2') }

      it "return queued jobs not included in the run group names" do
        Naf::QueuedJob.exclude_run_group_names(['test 2']).
          should == [included_job]
      end

      it "return all queued jobs when run group names are not specified" do
        Naf::QueuedJob.exclude_run_group_names([]).
          should == [included_job, excluded_job]
      end
    end

    describe "#runnable_by_machine" do
      let!(:included_job) { FactoryGirl.create(:queued_job, application_run_group_name: 'test 1') }
      let!(:excluded_job) { FactoryGirl.create(:queued_job, application_run_group_name: 'test 2') }

      it "return queued jobs not included in the run group names" do
        Naf::QueuedJob.exclude_run_group_names(['test 2']).
          should == [included_job]
      end

      it "return all queued jobs when run group names are not specified" do
        Naf::QueuedJob.exclude_run_group_names([]).
          should == [included_job, excluded_job]
      end
    end

    describe "#prerequisites_finished" do
      let!(:prerequesite_needed_historical_job) { FactoryGirl.create(:job, finished_at: nil) }
      let!(:prerequesite_historical_job) { FactoryGirl.create(:job) }
      let!(:historical_job) { FactoryGirl.create(:job) }
      let!(:prerequesite_needed_queued_job) {
        FactoryGirl.create(:queued_job, id: prerequesite_needed_historical_job.id,
                                        historical_job: prerequesite_needed_historical_job)
      }
      let!(:queued_job) {
        FactoryGirl.create(:queued_job, id: historical_job.id,
                                        historical_job: historical_job)
      }
      let!(:prerequesite) {
        FactoryGirl.create(:historical_job_prerequesite, prerequisite_historical_job: prerequesite_historical_job,
                                                         historical_job: prerequesite_needed_historical_job)
      }

      it "return queued jobs not included in the run group names" do
        Naf::QueuedJob.prerequisites_finished.
          should == [queued_job]
      end
    end

    describe "#weight_available_on_machine" do
      let!(:machine) { mock_model(Machine) }
      let!(:cpu_affinity_slot) { mock_model(MachineAffinitySlot, affinity_id: 4, affinity_parameter: 5.0) }
      let!(:memory_affinity_slot) { mock_model(MachineAffinitySlot, affinity_id: 5, affinity_parameter: 5.0) }
      let!(:queued_job) { FactoryGirl.create(:queued_job) }

      before do
        ::Naf::RunningJob.any_instance.stub(:affinity_weights).
          and_return(1 => 0.0, 2 => 0.0, 3 => 0.0, 4 => 1.0, 5 => 1.0)
      end

      it "return queued job when machine has cpus left" do
        memory_affinity_slot = mock_model(MachineAffinitySlot, affinity_id: 5, affinity_parameter: 0.0)
        machine.stub(:machine_affinity_slots).and_return([cpu_affinity_slot, memory_affinity_slot])
        ::Naf::QueuedJob.stub(:check_weight_sum).
          and_return([])

        ::Naf::QueuedJob.weight_available_on_machine(machine).
          should == [queued_job]
      end

      it "return queued job when machine has cpus and memory left" do
        machine.stub(:machine_affinity_slots).and_return([cpu_affinity_slot, memory_affinity_slot])
        ::Naf::QueuedJob.stub(:check_weight_sum).
          and_return([])

        ::Naf::QueuedJob.weight_available_on_machine(machine).
          should == [queued_job]
      end

      it "return queued job when machine does not have cpu/memory restriction" do
        machine.stub(:machine_affinity_slots).and_return([])

        ::Naf::QueuedJob.weight_available_on_machine(machine).
          should == [queued_job]
      end
    end

    describe "#check_weight_sum" do
      let!(:queued_job) { FactoryGirl.create(:queued_job) }
      let!(:affinity) { FactoryGirl.create(:affinity, id: 4, affinity_name: 'cpus') }
      let!(:affinity_tab) { FactoryGirl.create(:job_affinity_tab_base,
                                               historical_job: queued_job.historical_job,
                                               affinity_id: affinity.id,
                                               affinity_parameter: 1)}
      it "does not return queued job when machine has cpus left" do
        ::Naf::QueuedJob.check_weight_sum(4, 1, 3).
          should == []
      end

      it "does not return queued job when job does not have cpu affinity" do
        affinity_tab.delete
        ::Naf::QueuedJob.check_weight_sum(4, 1, 3).
          should == []
      end

      it "return jobs when machine does not have cpus left" do
        ::Naf::QueuedJob.check_weight_sum(4, 3, 3).
          should == [queued_job]
      end
    end

  end
end
