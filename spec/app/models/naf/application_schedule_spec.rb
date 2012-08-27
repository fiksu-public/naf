require 'spec_helper'

module Naf
  describe ApplicationSchedule do
    
    let(:schedule)                 { FactoryGirl.create(:schedule) }



    context "with regard to creation" do
      let(:incomplete_schedule_base) { FactoryGirl.build(:schedule_base) }
      let(:schedule_base)            { FactoryGirl.build(:schedule_base, :run_interval => 1, :application_run_group_name => "Awesome Run Group") }
    
      it "should not save without a specified run interval or run group name" do
        incomplete_schedule_base.save.should_not be_true
      end
      
      it "should save when a run interval and run group name are specified" do
        schedule_base.save.should be_true
      end
      
      it "should not save when it is enabled and has taken another's application" do
        application = schedule.application
        schedule_base.application_id = application.id
        schedule_base.enabled.should be_true
        schedule_base.save.should_not be_true
      end

      it "should save when it is not enabled and has taken another's application" do
        application = schedule.application
        schedule_base.application_id = application.id
        schedule_base.enabled = false
        schedule_base.enabled.should_not be_true
        schedule_base.save.should be_true
      end

      it "should not save when not enabled and visible" do
        schedule_base.enabled = true
        schedule_base.visible = false
        schedule_base.save.should_not be_true
      end
     
    end


    context "with regard to the schedules_lock" do
      it "should not have two processes acquire the schedule lock"

    end

  end
end
