require 'spec_helper'

module Naf
  describe MachineRunnerInvocation do
    # Mass-assignment
    [:machine_runner_id,
     :pid,
     :is_running,
     :wind_down].each do |a|
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

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:machine_runner_id) }
    it { should validate_presence_of(:pid) }

  end
end
