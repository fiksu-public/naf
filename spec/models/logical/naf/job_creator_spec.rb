require 'spec_helper'

module Logical
  module Naf
    
    describe JobCreator do
      
      context "with regard to queuing from an application_schedule" do
        
        context "a new queued job should get from an application_schedule" do
          
          let(:app_schedule_for_canary) {
            tab = FactoryGirl.create(:canary_app_schedule_affinity_tab)
            tab.application_schedule
          }
          
          let(:job_creator) {JobCreator.new}
          
          before(:all) {
            ::Naf::Job.delete_all
            ::Naf::JobAffinityTab.delete_all
            ::Naf::ApplicationSchedule.destroy_all
          }
          
          it "affinities" do
            job_creator.queue_application_schedule(app_schedule_for_canary)
            ::Naf::Job.first.job_affinity_tabs.map(&:affinity_id).should eql(app_schedule_for_canary.application_schedule_affinity_tabs.map(&:affinity_id))
          end
          
          
        end
        
      end
    end
  end
end
  
