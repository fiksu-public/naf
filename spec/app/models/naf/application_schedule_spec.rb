require 'spec_helper'

module Naf
  describe ApplicationSchedule do
    
    let(:schedule)                 { FactoryGirl.create(:schedule) }
    let(:incomplete_schedule_base) { FactoryGirl.build(:schedule_base) }
    let(:schedule_base)            { FactoryGirl.build(:schedule_base, :run_interval => 1, :application_run_group_name => "Awesome Run Group") }
    
    it "should not save without a specified run interval or run group name" do
      incomplete_schedule_base.save.should_not be_true
    end
    
    it "should save when a run interval and run group name are specified" do
      schedule_base.save.should be_true
    end


  end
end
