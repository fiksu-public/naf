require 'spec_helper'

module Logical
  module Naf
    describe Application do
      let(:columns) { [:id,
                       :title,
                       :short_name,
                       :script_type_name,
                       :application_run_group_name,
                       :application_run_group_restriction_name,
                       :application_run_group_limit,
                       :enabled,
                       :enqueue_backlogs,
                       :run_time,
                       :affinities,
                       :prerequisites,
                       :deleted,
                       :visible] }
      let(:physical_app) { FactoryGirl.create(:application) }
      let!(:logical_app) { Application.new(physical_app) }
      let(:scheduled_physical_app) {
        FactoryGirl.create(:scheduled_application, application_schedule: FactoryGirl.create(:schedule_at_time))
      }

      context "Class Methods" do
        it "search method should return array of wrapper around physical application" do
          app = logical_app
          Application.search(params: nil).map(&:id).should include(app.id)
          Application.search(params: nil).should have(1).items
          Application.search(params: nil).should be_a(Array)
        end
      end

      it "should delegate command to the physical app" do
        logical_app.should_receive(:command).and_return("")
        logical_app.command
      end

      it "to_hash should have the specified columns" do
        logical_app.to_hash.keys.should == columns
      end

      it "should render run_start_minute" do
        scheduled_physical_app.application_schedule.run_start_minute.should be_a(Fixnum)

        Application.new(scheduled_physical_app).run_start_minute.should be_a(String)
      end

      it "should delegate methods to its schedule" do
        methods = [:application_run_group_restriction_name,
                   :run_interval,
                   :application_run_group_name,
                   :run_start_minute]
        schedule = scheduled_physical_app.application_schedule
        logical_scheduled_app = Application.new(scheduled_physical_app)

        methods.each do |m|
          schedule.should_receive(m).and_return(nil)
        end

        methods.each do |m|
          logical_scheduled_app.send(m)
        end
      end
    end

  end
end
