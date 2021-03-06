require 'spec_helper'

module Naf
  describe Affinity do
    let!(:normal) { FactoryGirl.create(:normal_affinity) }
    let(:canary) { FactoryGirl.create(:canary_affinity) }
    let(:perennial) { FactoryGirl.create(:perennial_affinity) }
    let!(:machine) { FactoryGirl.create(:machine) }
    let!(:machine_classification) { FactoryGirl.create(:machine_affinity_classification) }
    let!(:machine_affinity) {
      FactoryGirl.create(:affinity, id: 5,
                                    affinity_classification_id: machine_classification.id,
                                    affinity_name: machine.id.to_s)
    }


    # Mass-assignment
    [:affinity_classification_id,
     :affinity_name,
     :selectable,
     :affinity_short_name,
     :affinity_note].each do |a|
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

    it { should belong_to(:affinity_classification) }
    it { should have_many(:application_schedule_affinity_tabs) }
    it { should have_many(:machine_affinity_slots) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:affinity_classification_id) }
    it { should validate_presence_of(:affinity_name) }
    it { should validate_uniqueness_of(:affinity_short_name) }

    ['', 'aa', 'aA', 'Aa', 'AA', '_a', 'a1', 'A1', '_9'].each do |v|
      it { should allow_value(v).for(:affinity_short_name) }
    end

    ['1_', '3A', '9a'].each do |v|
      it { should_not allow_value(v).for(:affinity_short_name) }
    end

    context "keeps with the starting seed rows for the table" do
      it "for normal" do
        normal.id.should == 1
      end

      it "for canary" do
        canary.id.should == 2
      end

      it "for perennial" do
        perennial.id.should == 3
      end
    end

    context "with regard to creation" do
      let(:invalid_affinity) { FactoryGirl.build(:affinity, affinity_name: "") }

      it "it should not be valid with an empty name" do
        invalid_affinity.save.should_not be_true
        invalid_affinity.should have(2).errors_on(:affinity_name)
      end
    end

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regard to delegation" do
      let(:classification) { normal.affinity_classification }

      it "should delegate the affinity_classfication_name method" do
        classification.should_receive(:affinity_classification_name)
        normal.affinity_classification_name
      end
    end

    describe '#validate_affinity_name' do
      it 'return nil when classification is not present' do
        normal.affinity_classification = nil
        normal.validate_affinity_name.should be_nil
      end

      it 'return proper message when machine associated with affinity is not found' do
        normal.affinity_classification.affinity_classification_name = 'machine'
        normal.validate_affinity_name.should == "There isn't a machine with that id!"
      end

      it 'return proper message when pair value (affinity_classification_id, affinity_name) already exists' do
        normal.affinity_name = FactoryGirl.create(:machine).id.to_s
        normal.affinity_classification = machine_classification

        normal.validate_affinity_name.should == 'An affinity with the pair value (affinity_classification_id, affinity_name) already exists!'
      end
    end

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#selectable" do
      before do
        canary.update_attributes!(selectable: false)
        perennial.update_attributes!(selectable: false)
        machine_affinity.update_attributes!(selectable: false)
      end

      it "return only selectable affinities" do
        ::Naf::Affinity.selectable.should == [normal]
      end
    end

    describe "#deleted_machine_affinities" do
      it "return only affinities that are associated with deleted machines" do
        machine.update_attributes!(deleted: true, enabled: false)
        ::Naf::Affinity.deleted_machine_affinities.should == [machine_affinity]
      end
    end

    describe "#names_list" do
      before do
        canary.update_attributes!(selectable: false)
        perennial.update_attributes!(selectable: false)
      end

      it "return affinities not related to machine classification correctly" do
        ::Naf::Affinity.names_list.should == [['purpose, normal', 1], ['0.0.0.1', 5]]
      end

      it "return affinities related to machine classification correctly when short name is present" do
        machine_affinity.update_attributes!(affinity_short_name: 'machine_1')
        ::Naf::Affinity.names_list.should == [['purpose, normal', 1], ['machine_1', 5]]
      end

      it "return affinities related to machine classification correctly when affinity_name is used" do
        ::Naf::Affinity.names_list.should == [['purpose, normal', 1], ['0.0.0.1', 5]]
      end

      it "return affinities related to machine classification correctly when it is invalid" do
        machine_affinity.update_attributes!(affinity_name: '100')
        ::Naf::Affinity.names_list.should == [['purpose, normal', 1], ['Bad affinity: machine, 100', 5]]
      end
    end

  end
end
