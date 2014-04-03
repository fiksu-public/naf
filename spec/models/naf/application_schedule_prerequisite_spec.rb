require 'spec_helper'

module Naf
  describe ApplicationSchedulePrerequisite do
    # Mass-assignment
    [:application_schedule_id,
     :prerequisite_application_schedule_id].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should belong_to(:application_schedule) }
    it { should belong_to(:prerequisite_application_schedule) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:prerequisite_application_schedule_id) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:schedule_prerequisite) }
      it { should validate_uniqueness_of(:application_schedule_id).scoped_to(:prerequisite_application_schedule_id) }
    end

  end
end
