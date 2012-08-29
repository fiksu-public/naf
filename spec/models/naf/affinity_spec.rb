require 'spec_helper'


module Naf
  describe Affinity do
    let(:normal) { FactoryGirl.create(:normal_affinity) }
    let(:canary) { FactoryGirl.create(:canary_affinity) }
    let(:perennial) { FactoryGirl.create(:perennial_affinity) }
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
    context "with regard to delegation" do

      context "to affinity classification" do
        before(:each) do
          @classification = normal.affinity_classification
        end
        it "should delegate the affinity_classfication_name method" do
          @classification.should_receive(:affinity_classification_name)
          normal.affinity_classification_name
        end
      end

    end
    context "with regard to creation" do
      let(:invalid_affinity) { FactoryGirl.build(:affinity, :affinity_name => "") }
      it "it should not be valid with an empty name" do
        invalid_affinity.save.should_not be_true
        invalid_affinity.should have(2).errors_on(:affinity_name)
      end
    end
  end
end
