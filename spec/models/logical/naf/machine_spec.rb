require 'spec_helper'

module Logical
  module Naf

    describe Machine do
      let(:physical_machine) { FactoryGirl.create(:machine)  }

      let(:physical_machine_two) { FactoryGirl.create(:machine_two) }

      let(:columns) {[:id, :server_name, :server_address, :server_note, :enabled, :process_pool_size, :last_checked_schedules_at, :last_seen_alive_at, :log_level, :affinities, :marked_down]}
      

      it "to_hash should return with the specified columns" do
        logical_machine = Machine.new(physical_machine)
        logical_machine.to_hash.keys.should eql(columns)
      end

      it "should alias the thread_pool_size method, as process_pool_size" do
        logical_machine = Machine.new(physical_machine)
        logical_machine.should_receive(:thread_pool_size).and_return(5)
        logical_machine.process_pool_size
      end

      it "should render last_checked_schedules_at nicely" do
        physical_machine.mark_checked_schedule
        logical_machine = Machine.new(physical_machine)
        logical_machine.should_receive(:time_ago_in_words).and_return("")
        logical_machine.last_checked_schedules_at.should =~ /ago$/
      end

      it "should render last_seen_alive_at nicely" do
        physical_machine.mark_alive
        logical_machine = Machine.new(physical_machine)
        logical_machine.should_receive(:time_ago_in_words).and_return("")
        logical_machine.last_seen_alive_at.should =~ /ago$/
      end


      context "Class Methods," do
        it "all should return an array of logical wrappers around machines" do
          machine = physical_machine
          machine_two = physical_machine_two

          logical_machine = Machine.new(machine)
          Machine.all.map(&:id).should include(machine.id)
          Machine.all.map(&:id).should include(machine_two.id)
          Machine.all.should be_a(Array)
          Machine.all.should have(2).items
        end

      end





    end

  end
end

