require 'spec_helper'

module Naf
  describe Machine do

    let(:machine) { FactoryGirl.create(:machine) }

    context "when created" do

      it "should be found by the enabled scope" do
        machine_id = machine.id
        Machine.enabled.map(&:id).should include(machine_id)
      end

      it "should be stale" do
        machine.is_stale?(1).should be_true
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
        dying_machine = machine
        dying_machine.should_receive(:mark_processes_as_dead).and_return(nil)
        dying_machine.mark_machine_dead
        dying_machine.enabled.should be_false
      end
    end
      


  end
end
