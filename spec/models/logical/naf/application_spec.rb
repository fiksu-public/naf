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
          expect(Application.search(params: nil).map(&:id)).to include(logical_app.id)
          expect(Application.search(params: nil).size).to eq(2)
          expect(Application.search(params: nil)).to be_a(Array)
        end
      end

      it "should delegate command to the physical app" do
        expect(logical_app).to receive(:command).and_return("")
        logical_app.command
      end

      it "to_hash should have the specified columns" do
        expect(logical_app.to_hash.keys).to eq(columns)
      end
    end

  end
end
