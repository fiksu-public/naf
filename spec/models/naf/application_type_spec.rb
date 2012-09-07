require 'spec_helper'

module Naf
  describe ApplicationType do
    let(:rails)         {FactoryGirl.create(:rails_app_type) }
    let(:bash_command)  {FactoryGirl.create(:bash_command_app_type) }
    let(:bash_script)   {FactoryGirl.create(:bash_script_app_type)  }
    let(:ruby)          {FactoryGirl.create(:ruby_script_app_type)  }

    context "For a Rails Application" do
      let(:job) { FactoryGirl.create(:job, :application_type => rails) }
      it "has the starting id" do
        rails.id.should == 1
      end
      it "should invoke the rails_invocator" do
        rails.should_receive(:rails_invocator).and_return(nil)
        job.spawn
      end
    end
    context "For a bash command" do
      let(:job) { FactoryGirl.create(:job, :application_type => bash_command) }
      it "has the starting id" do
        bash_command.id.should == 2
      end
      it "should invoke the bash_command_invocator" do
        bash_command.should_receive(:bash_command_invocator).and_return(nil)
        job.spawn
      end
    end
    context "For a bash script" do
      let(:job) { FactoryGirl.create(:job, :application_type => bash_script) }
      it "has the starting id" do
        bash_script.id.should == 3
      end
      it "should invoke the bash_script_invocator" do
        bash_script.should_receive(:bash_script_invocator).and_return(nil)
        job.spawn
      end
    end
    context "For a ruby script" do
      let(:job) { FactoryGirl.create(:job, :application_type => ruby) }
      it "has the starting id" do
        ruby.id.should == 4
      end
      it "should invoke the ruby_script_invocator" do
        ruby.should_receive(:ruby_script_invocator).and_return(nil)
        job.spawn
      end
    end
  end
end
