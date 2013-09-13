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
          let(:job_creator) { JobCreator.new }

          before do
            ::Naf::HistoricalJob.delete_all
            ::Naf::HistoricalJobAffinityTab.delete_all
            ::Naf::ApplicationSchedule.destroy_all
            app_schedule_for_canary.enqueue_backlogs = true
          end

          it "affinities" do
            job_creator.queue_application_schedule(app_schedule_for_canary)
            ::Naf::HistoricalJob.first.historical_job_affinity_tabs.map(&:affinity_id).
              should == app_schedule_for_canary.application_schedule_affinity_tabs.map(&:affinity_id)
          end
        end
      end
    end

  end
end
