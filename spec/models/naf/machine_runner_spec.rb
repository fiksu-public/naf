require 'spec_helper'

module Naf
  describe MachineRunner do
    # Mass-assignment
    [:machine_id,
     :runner_cwd].each do |a|
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

    it { is_expected.to belong_to(:machine) }
    it { is_expected.to have_many(:machine_runner_invocations) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:machine_id) }
    it { is_expected.to validate_presence_of(:runner_cwd) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:machine_runner) }
      it { is_expected.to validate_uniqueness_of(:machine_id).scoped_to(:runner_cwd) }
    end

  end
end
