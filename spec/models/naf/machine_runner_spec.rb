require 'spec_helper'

module Naf
  describe MachineRunner do
    # Mass-assignment
    [:machine_id,
     :runner_cwd].each do |a|
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

    it { should belong_to(:machine) }
    it { should have_many(:machine_runner_invocations) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:machine_id) }
    it { should validate_presence_of(:runner_cwd) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:machine_runner) }
      it { should validate_uniqueness_of(:machine_id).scoped_to(:runner_cwd) }
    end

  end
end
