require 'spec_helper'
module Naf
  describe Application do
    let(:app) { FactoryGirl.create(:application) }
    context "upon creation" do

      let(:app_base) { FactoryGirl.build(:application_base, command: "::Naf::HistoricalJob.test hello_world",
                                                            title: "Test Hello World") }
      let(:incomplete_app_base) { FactoryGirl.build( :application_base) }

      it "should save with a command and title specified" do
        app_base.save.should be_true
      end

      it "should not save without a command or a title" do
        incomplete_app_base.save.should_not be_true
      end

      context "with regard to the title" do
        it "should not save when another title is taken" do
          app_2 = FactoryGirl.build(:application, title: app.title)
          app_2.save.should_not be_true
          app_2.should have(1).error_on(:title)
        end
      end
    end
    context "with regard to delegation" do
      context "to application_type" do
        before(:each) do
          @application_type = app.application_type
        end
        it "should delegate the script_type_name" do
          @application_type.should_receive(:script_type_name)
          app.script_type_name
        end
      end
    end
  end
end
