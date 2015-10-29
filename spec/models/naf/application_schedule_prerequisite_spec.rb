require 'spec_helper'

module Naf
  describe ApplicationSchedulePrerequisite do
    # Mass-assignment
    [:application_schedule_id,
     :prerequisite_application_schedule_id].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:application_schedule) }
    it { is_expected.to belong_to(:prerequisite_application_schedule) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:prerequisite_application_schedule_id) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:schedule_prerequisite) }
      it { is_expected.to validate_uniqueness_of(:application_schedule_id).scoped_to(:prerequisite_application_schedule_id) }
    end

  end
end
