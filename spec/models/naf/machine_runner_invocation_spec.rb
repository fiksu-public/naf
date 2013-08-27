require 'spec_helper'

module Naf
  describe MachineRunnerInvocation do
    # Mass-assignment
    [:machine_runner_id,
     :pid,
     :is_running,
     :wind_down,
     :commit_information,
     :branch_name,
     :repository_name,
     :deployment_tag].each do |a|
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
    it { should validate_presence_of(:commit_information) }
    it { should validate_presence_of(:branch_name) }
    it { should validate_presence_of(:repository_name) }
    it { should validate_presence_of(:deployment_tag) }

  end
end
