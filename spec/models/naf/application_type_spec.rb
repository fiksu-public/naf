require 'spec_helper'

module Naf
  describe ApplicationType do
    let(:rails)         {FactoryGirl.create(:rails_app_type) }
    let(:bash_command)  {FactoryGirl.create(:bash_command_app_type) }
    let(:bash_script)   {FactoryGirl.create(:bash_script_app_type)  }
    let(:ruby)          {FactoryGirl.create(:ruby_script_app_type)  }

    context "For a Rails Application" do
      it "has the starting id" do
        rails.id.should == 1
      end
    end
    context "For a bash command" do
      it "has the starting id" do
        bash_command.id.should == 2
      end
    end
    context "For a bash script" do
      it "has the starting id" do
        bash_script.id.should == 3
      end
    end
    context "For a ruby script" do
      it "has the starting id" do
        ruby.id.should == 4
      end
    end
  end
end
