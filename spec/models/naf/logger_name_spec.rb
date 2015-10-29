require 'spec_helper'

module Naf
  describe LoggerName do
    # Mass-assignment
    [:name].each do |a|
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
    it { is_expected.to have_many(:logger_styles) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:name) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_name) }
      it { is_expected.to validate_uniqueness_of(:name) }
    end

  end
end
