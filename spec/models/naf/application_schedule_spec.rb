require 'spec_helper'

module Naf
  describe ApplicationSchedule do
    
    let(:schedule)                 { FactoryGirl.create(:schedule) }



    context "with regard to creation and updating" do
      let(:incomplete_schedule_base) { FactoryGirl.build(:schedule_base) }
      let(:schedule_base)            { FactoryGirl.build(:schedule_base, :run_interval => 1, :application_run_group_name => "Awesome Run Group") }
    
      it "should not save without a specified run interval or run group name" do
        incomplete_schedule_base.save.should_not be_true
      end
      
      it "should save when a run interval and run group name are specified" do
        schedule_base.save.should be_true
      end
      

      context "when it has taken another's application" do
        it "should not save if enabled" do
          application = schedule.application
          schedule_base.application_id = application.id
          schedule_base.enabled.should be_true
          schedule_base.save.should_not be_true
          schedule_base.should have(1).error_on(:application_id)
        end

        it "should save when not enabled" do
          application = schedule.application
          schedule_base.application_id = application.id
          schedule_base.enabled = false
          schedule_base.enabled.should_not be_true
          schedule_base.save.should be_true
        end
      end

      it "should not save when not enabled and visible" do
        schedule_base.enabled = true
        schedule_base.visible = false
        schedule_base.save.should_not be_true
        schedule_base.should have(1).error_on(:visible)
        schedule_base.should have(1).error_on(:enabled)
      end

      context "when a run_start_minute is specified" do
        it "should not save when the run_interval is not a multiple of one day" do
          schedule_base.run_start_minute = 5 # 12:05 AM
          schedule_base.run_interval = 30
          schedule_base.save.should_not be_true
          schedule_base.should have(1).error_on(:run_interval)
        end
        
        it "should save when the run_interval is a multiple of one day" do
          schedule_base.run_start_minute = 5 # 12:05 AM
          schedule_base.run_interval = 2*24*60 # Every Two Days
          schedule_base.save.should be_true
        end
      end
     
    end


    context "with regard to the schedules_lock" do
      it "should not have two processes acquire the schedule lock"

    end

  end
end
