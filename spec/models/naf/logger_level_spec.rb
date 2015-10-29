require 'spec_helper'

module Naf
  describe LoggerLevel do
    # Mass-assignment
    [:level].each do |a|
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

    it { is_expected.to have_many(:logger_style_names) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:level) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_level) }
      it { is_expected.to validate_uniqueness_of(:level) }
    end

  end
end
