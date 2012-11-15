require 'spec_helper'

module Logical
  module Naf
    
    describe Application do
      
      let(:columns)      { [:id, :title, :script_type_name, :application_run_group_name, :application_run_group_restriction_name, :run_start_minute, :run_interval] }
      let(:physical_app) {  FactoryGirl.create(:application) }
      let(:logical_app)  {  Application.new(physical_app)    }
      let(:scheduled_physical_app) {  FactoryGirl.create(:scheduled_application, :application_schedule => FactoryGirl.create(:schedule_at_time)) }
      

      context "Class Methods" do
        it "all method should return array of wrapper around physical application" do
          app = logical_app
          Application.all.map(&:id).should include(app.id)
          Application.all.should have(1).items
          Application.all.should be_a(Array)
        end
      end

      it "should delegate command to the physical app" do
        app = logical_app
        app.should_receive(:command).and_return("")
        app.command
      end

      it "to_hash should have the specified columns" do
        logical_app.to_hash.keys.should eql(columns)
      end

      it "should render run_start_minute" do
        scheduled_app = scheduled_physical_app
        scheduled_app.application_schedule.run_start_minute.should be_a(Fixnum)
        Application.new(scheduled_app).run_start_minute.should be_a(String)
      end

      it "should delegate methods to its schedule" do
        methods = [:application_run_group_restriction_name, :run_interval, :application_run_group_name, :run_start_minute]
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
