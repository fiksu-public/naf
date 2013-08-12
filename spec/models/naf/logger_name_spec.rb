require 'spec_helper'

module Naf
  describe LoggerName do
    # Mass-assignment
    [:name].each do |a|
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
    it { should have_many(:logger_styles) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:name) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_name) }
      it { should validate_uniqueness_of(:name) }
    end

  end
end
