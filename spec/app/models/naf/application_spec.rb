require 'spec_helper'
module Naf
  describe Application do
    
    context "upon creation" do
      
      let(:app)                    { FactoryGirl.create(:application) }
      let(:app_base)               { FactoryGirl.build(:application_base, :command => "::Naf::Job.test hello_world", :title => "Test Hello World") }
      let(:incomplete_app_base)    { FactoryGirl.build( :application_base) }
      
      it "should save with a command and title specified" do
        app_base.save.should be_true
      end

      it "should not save without a command or a title" do
        incomplete_app_base.save.should_not be_true
      end
    end
  end
end
