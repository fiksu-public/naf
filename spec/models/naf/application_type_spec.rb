require 'spec_helper'

module Naf
  describe ApplicationType do
    let(:rails) { rails_app_type() }
    let(:bash_command) { FactoryGirl.create(:bash_command_app_type) }
    let(:bash_script) { FactoryGirl.create(:bash_script_app_type) }
    let(:ruby) { FactoryGirl.create(:ruby_script_app_type) }
    let!(:job) { FactoryGirl.create(:job) }

    # Mass-assignment
    [:enabled,
     :script_type_name,
     :description,
     :invocation_method].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at,
     :updated_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to have_many(:applications) }
    it { is_expected.to have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:script_type_name) }
    it { is_expected.to validate_presence_of(:invocation_method) }

    context "For a Rails Application" do
      before do
        job.application_type = rails
        job.save!
      end

      it "should invoke the rails_invocator" do
        expect(rails).to receive(:rails_invocator).and_return(nil)
        job.spawn
      end
    end

    context "For a bash command" do
      before do
        job.application_type = bash_command
        job.save!
      end

      it "should invoke the bash_command_invocator" do
        expect(bash_command).to receive(:bash_command_invocator).and_return(nil)
        job.spawn
      end
    end

    context "For a bash script" do
      before do
        job.application_type = bash_script
        job.save!
      end

      it "should invoke the bash_script_invocator" do
        expect(bash_script).to receive(:bash_script_invocator).and_return(nil)
        job.spawn
      end
    end

    context "For a ruby script" do
      before do
        job.application_type = ruby
        job.save!
      end

      it "should invoke the ruby_script_invocator" do
        expect(ruby).to receive(:ruby_script_invocator).and_return(nil)
        job.spawn
      end
    end

  end
end
