require 'spec_helper'

module Naf

  describe ApplicationRunGroupRestriction do
    let(:no_restriction) {FactoryGirl.create(:no_restriction) }
    let(:one_at_a_time)  {FactoryGirl.create(:one_at_a_time_restriction) }
    let(:one_per_machine){FactoryGirl.create(:one_per_machine_restriction) }
    
    context "keeps with the starting rows table" do
      it "For no restrictions" do
        no_restriction.id.should == ApplicationRunGroupRestriction::NO_RESTRICTIONS
      end
      it "For one at a time" do
        one_at_a_time.id.should == ApplicationRunGroupRestriction::ONE_AT_A_TIME
      end
      it "For one per machine" do
        one_per_machine.id.should == ApplicationRunGroupRestriction::ONE_PER_MACHINE
      end
    end
  end

end
