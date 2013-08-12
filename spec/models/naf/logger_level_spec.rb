require 'spec_helper'

module Naf
  describe LoggerLevel do
    # Mass-assignment
    [:level].each do |a|
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

    it { should have_many(:logger_style_names) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:level) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_level) }
      it { should validate_uniqueness_of(:level) }
    end

  end
end
