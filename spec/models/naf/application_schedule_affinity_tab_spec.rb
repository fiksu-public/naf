require 'spec_helper'

module Naf
  describe ApplicationScheduleAffinityTab do
    let(:tab) { FactoryGirl.create(:normal_app_schedule_affinity_tab) }

    context "with regard to delegation" do
      context "to affinity" do
        before(:each) do
          @affinity = tab.affinity
        end
        it "should delegate affinity name" do
          @affinity.should_receive(:affinity_name)
          tab.affinity_name
        end
        it "should delegate affinity_classification_name" do
          @affinity.should_receive(:affinity_classification_name)
          tab.affinity_classification_name
        end
      end
      context "to application schedule" do
        before(:each) do
          @schedule = tab.application_schedule
        end
        it "should call the title method" do
          @schedule.should_receive(:title)
          tab.script_title
        end
      end
    end
  end
end
