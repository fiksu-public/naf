require 'spec_helper'

module Naf
  describe MachineAffinitySlot do
    let(:slot) { FactoryGirl.create(:normal_machine_affinity_slot) }

    context "with regard to delegation" do
      context "to machine" do
        before(:each) do
          @machine = slot.machine
        end
        it "should delegate the server_address method" do
          @machine.should_receive(:server_address)
          slot.machine_server_address
        end
        it "should delegate the server_name method" do
          @machine.should_receive(:server_name)
          slot.machine_server_name
        end
      end
    end

  end
end
