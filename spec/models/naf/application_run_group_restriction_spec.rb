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

  end
end
