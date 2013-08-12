require 'spec_helper'

module Naf
  describe MachineAffinitySlot do
    let(:slot) { FactoryGirl.create(:normal_machine_affinity_slot) }

    # Mass-assignment
    [:machine_id,
     :affinity_id,
     :required,
     :affinity_parameter].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should belong_to(:machine) }
    it { should belong_to(:affinity) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:machine_id) }
    it { should validate_presence_of(:affinity_id) }
    pending { should validate_uniqueness_of(:affinity_id).scoped_to(:machine_id) }

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regard to delegation" do
      it "deleage to affinity_name method" do
        slot.affinity.should_receive(:affinity_name)
        slot.affinity_name
      end

      it "delegate to affinity_classification_name method" do
        slot.affinity.should_receive(:affinity_classification_name)
        slot.affinity_classification_name
      end

      it "delegate to affinity_short_name method" do
        slot.affinity.should_receive(:affinity_short_name)
        slot.affinity_short_name
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#machine_server_address" do
      it "return the correct address" do
        slot.machine_server_address.should == '0.0.0.1'
      end
    end

    describe "#machine_server_name" do
      before do
        slot.machine.server_name = 'Machine1'
      end

      it "return the correct name" do
        slot.machine_server_name.should == 'Machine1'
      end
    end

  end
end
