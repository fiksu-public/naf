require 'spec_helper'

module Logical
  module Naf

    describe Application do
      let(:columns) { [:id,
                       :title,
                       :short_name,
                       :script_type_name,
                       :application_schedules,
                       :deleted] }
      let(:physical_app) { FactoryGirl.create(:application) }
      let!(:logical_app) { Application.new(physical_app) }
      let(:scheduled_physical_app) { FactoryGirl.create(:scheduled_application) }

      before do
        physical_app.application_schedules << FactoryGirl.create(:schedule_base)
      end

      context "Class Methods" do
        it "search method should return array of wrapper around physical application" do
          Application.search(params: nil).map(&:id).should include(logical_app.id)
          Application.search(params: nil).should have(2).items
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
    end

  end
end
