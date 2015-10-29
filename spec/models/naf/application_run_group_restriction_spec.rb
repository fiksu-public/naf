require 'spec_helper'

module Naf
  describe ApplicationRunGroupRestriction do
    # Mass-assignment
    [:application_run_group_restriction_name].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to have_many(:application_schedules) }
    it { is_expected.to have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:application_run_group_restriction_name) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#no_limit" do
      let!(:no_limit) { FactoryGirl.create(:no_limit) }

      it "return the no limit group restriction" do
        expect(::Naf::ApplicationRunGroupRestriction.no_limit).to eq(no_limit)
      end
    end

    describe "#limited_per_machine" do
      let!(:limited_per_machine) { FactoryGirl.create(:limited_per_machine) }

      it "return the limited per machine group restriction" do
        expect(::Naf::ApplicationRunGroupRestriction.limited_per_machine).to eq(limited_per_machine)
      end
    end

    describe "#limited_per_all_machines" do
      let!(:limited_per_all_machines) { FactoryGirl.create(:limited_per_all_machines) }

      it "return the limited per all machines group restriction" do
        expect(::Naf::ApplicationRunGroupRestriction.limited_per_all_machines).to eq(limited_per_all_machines)
      end
    end

  end
end
