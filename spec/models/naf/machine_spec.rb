require 'spec_helper'

module Naf
  describe Machine do

    let(:machine) { FactoryGirl.create(:machine) }

    context "with regard to checking the schedules" do
      before(:each) do
        machine.mark_checked_schedule
      end
      it "should be time to check the schedules if it's been longer than the check period" do
        check_period = Time.now - Machine.last_time_schedules_were_checked
        Machine.is_it_time_to_check_schedules?(check_period).should be_true
      end
      it "should not be time to check the schedules if it's been shorter than the check period" do
        Machine.is_it_time_to_check_schedules?(1.minute).should be_false
      end
    end
      

    context "when created" do

      it "should not save with a bad address" do
        bad_machine = FactoryGirl.build(:machine, :server_address => "21312")
        bad_machine.save.should_not be_true
        bad_machine.should have(1).error_on(:server_address)
      end

      it "should be found by the enabled scope" do
        Machine.enabled.should include(machine)
      end

      it "should be stale" do
        machine.is_stale?(1).should be_true
      end
    end

    context "when fetching jobs" do
      it "should ask Naf::Job to find jobs assigned to it" do
        Job.should_receive(:fetch_assigned_jobs).with(machine).and_return([])
        machine.assigned_jobs
      end
      it "should ask Naf::Job to find the next job for it" do
        Job.should_receive(:fetch_next_job).with(machine).and_return([])
        machine.fetch_next_job
      end
    end

    context "when updating its status" do
      before(:each) do
        @time_before_update = Time.zone.now
      end

      it "should mark schedules as checked" do
        machine.mark_checked_schedule
        machine.last_checked_schedules_at.should be > @time_before_update
        machine.last_checked_schedules_at.should be < Time.zone.now
      end

      it "should mark itself as alive" do
        machine.mark_alive
        machine.last_seen_alive_at.should be > @time_before_update
        machine.last_seen_alive_at.should be < Time.zone.now
      end
    end

    context "when marking itself as dead" do
      it "should un-enable itself, and mark child proceses as dead" do
        mock_machine_logger = mock('machine_logger')
        mock_machine_logger.should_receive(:alarm).and_return(nil)
        dying_machine = machine
        dying_machine.should_receive(:machine_logger).and_return(mock_machine_logger)
        dying_machine.should_receive(:mark_processes_as_dead).and_return(nil)
        dying_machine.mark_machine_down(dying_machine)
        dying_machine.marked_down.should be_true
      end
    end
      


  end
end
