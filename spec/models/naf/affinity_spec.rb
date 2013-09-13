require 'spec_helper'

module Naf
  describe Affinity do
    let!(:normal) { FactoryGirl.create(:normal_affinity) }
    let(:canary) { FactoryGirl.create(:canary_affinity) }
    let(:perennial) { FactoryGirl.create(:perennial_affinity) }

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

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#selectable" do
      before do
        canary.update_attributes!(selectable: false)
        perennial.update_attributes!(selectable: false)
      end

      it "return only selectable affinities" do
        ::Naf::Affinity.selectable.should == [normal]
      end
    end

  end
end
