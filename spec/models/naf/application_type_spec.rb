require 'spec_helper'

module Naf
  describe ApplicationType do
    let(:rails) { FactoryGirl.create(:rails_app_type) }
    let(:bash_command) { FactoryGirl.create(:bash_command_app_type) }
    let(:bash_script) { FactoryGirl.create(:bash_script_app_type) }
    let(:ruby) { FactoryGirl.create(:ruby_script_app_type) }
    let!(:job) { FactoryGirl.create(:job) }


    # Mass-assignment
    [:enabled,
     :script_type_name,
     :description,
     :invocation_method].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at,
     :updated_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should have_many(:applications) }
    it { should have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:script_type_name) }
    it { should validate_presence_of(:invocation_method) }

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    context "For a Rails Application" do
      before do
        job.application_type = rails
        job.save!
      end

      it "has the starting id" do
        rails.id.should == 1
      end

      it "should invoke the rails_invocator" do
        rails.should_receive(:rails_invocator).and_return(nil)
        job.spawn
      end
    end

    context "For a bash command" do
      before do
        job.application_type = bash_command
        job.save!
      end

      it "has the starting id" do
        bash_command.id.should == 2
      end

      it "should invoke the bash_command_invocator" do
        bash_command.should_receive(:bash_command_invocator).and_return(nil)
        job.spawn
      end
    end

    context "For a bash script" do
      before do
        job.application_type = bash_script
        job.save!
      end

      it "has the starting id" do
        bash_script.id.should == 3
      end

      it "should invoke the bash_script_invocator" do
        bash_script.should_receive(:bash_script_invocator).and_return(nil)
        job.spawn
      end
    end

    context "For a ruby script" do
      before do
        job.application_type = ruby
        job.save!
      end

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
