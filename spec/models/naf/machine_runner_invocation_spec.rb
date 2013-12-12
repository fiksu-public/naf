require 'spec_helper'

module Naf
  describe MachineRunnerInvocation do
    # Mass-assignment
    [:machine_runner_id,
     :pid,
     :dead_at,
     :wind_down_at,
     :commit_information,
     :branch_name,
     :repository_name,
     :deployment_tag,
     :uuid].each do |a|
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

    it { should belong_to(:machine_runner) }
    it { should have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:machine_runner_id) }
    it { should validate_presence_of(:pid) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#recently_marked_dead" do
      let!(:invocation) { FactoryGirl.create(:machine_runner_invocation, dead_at: Time.zone.now - 1.hour) }
      before do
        FactoryGirl.create(:machine_runner_invocation, dead_at: Time.zone.now - 40.hours)
      end

      it "return the correct invocation" do
        ::Naf::MachineRunnerInvocation.recently_marked_dead(24.hours).should == [invocation]
      end
    end

  end
end
