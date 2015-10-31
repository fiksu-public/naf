require 'spec_helper'

module Naf
  describe MachineAffinitySlot do
    let(:machine) { mock_model(Machine, server_address: '0.0.0.1', server_name: 'Machine1') }
    let!(:slot) { FactoryGirl.create(:normal_machine_affinity_slot) }

    # Mass-assignment
    [:machine_id,
     :affinity_id,
     :required,
     :affinity_parameter].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:machine) }
    it { is_expected.to belong_to(:affinity) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:machine_id) }
    it { is_expected.to validate_presence_of(:affinity_id) }

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regard to delegation" do
      it "deleage to affinity_name method" do
        expect(slot.affinity).to receive(:affinity_name)
        slot.affinity_name
      end

      it "delegate to affinity_classification_name method" do
        expect(slot.affinity).to receive(:affinity_classification_name)
        slot.affinity_classification_name
      end

      it "delegate to affinity_short_name method" do
        expect(slot.affinity).to receive(:affinity_short_name)
        slot.affinity_short_name
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    before do
      slot.machine = machine
    end

    describe "#machine_server_address" do
      it "return the correct address" do
        expect(slot.machine_server_address).to eq('0.0.0.1')
      end
    end

    describe "#machine_server_name" do
      it "return the correct name" do
        expect(slot.machine_server_name).to eq('Machine1')
      end
    end

  end
end
