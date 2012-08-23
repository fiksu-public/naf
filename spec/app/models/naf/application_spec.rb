require 'spec_helper'
module Naf
  describe Application do
    
    describe "saving and validations" do
      
      let(:app)                    { FactoryGirl.create(:rails_application, :command => "::Naf::Job.test hello_world") }
      let(:unsaved_app)            { FactoryGirl.create(:rails_application, :command => "::Naf::Job.test hello_world") }
      let(:unsaved_incomplete_app) { FactoryGirl.build( :rails_application) }
      
      it "should save with a command" do
        unsaved_app.save.should be_true
      end

      it "should not save without a command" do
        unsaved_incomplete_app.save.should_not be_true
      end

    end
  end
end
