require 'spec_helper'

module Naf
  describe LoggerStyleName do
    # Mass-assignment
    [:logger_style_id,
     :logger_name_id,
     :logger_level_id].each do |a|
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

    it { should belong_to(:logger_name) }
    it { should belong_to(:logger_style) }
    it { should belong_to(:logger_level) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:logger_name_id) }
    it { should validate_presence_of(:logger_level_id) }
    it { should validate_presence_of(:logger_style_id) }

    describe "uniqueness"do
      subject { FactoryGirl.create(:logger_style_name) }
      it { should validate_uniqueness_of(:logger_style_id).scoped_to(:logger_name_id) }
    end

  end
end
