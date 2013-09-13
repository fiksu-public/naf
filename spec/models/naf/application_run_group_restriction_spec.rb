require 'spec_helper'

module Naf
  describe ApplicationRunGroupRestriction do
    # Mass-assignment
    [:application_run_group_restriction_name].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should have_many(:application_schedules) }
    it { should have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_run_group_restriction_name) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#no_limit" do
      let!(:no_limit) { FactoryGirl.create(:no_limit) }

      it "return the no limit group restriction" do
        ::Naf::ApplicationRunGroupRestriction.no_limit.should == no_limit
      end
    end

    describe "#limited_per_machine" do
      let!(:limited_per_machine) { FactoryGirl.create(:limited_per_machine) }

      it "return the limited per machine group restriction" do
        ::Naf::ApplicationRunGroupRestriction.limited_per_machine.should == limited_per_machine
      end
    end

    describe "#limited_per_all_machines" do
      let!(:limited_per_all_machines) { FactoryGirl.create(:limited_per_all_machines) }

      it "return the limited per all machines group restriction" do
        ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines.should == limited_per_all_machines
      end
    end

  end
end
