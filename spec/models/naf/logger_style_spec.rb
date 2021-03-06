require 'spec_helper'

module Naf
  describe LoggerStyle do
    let!(:logger_style) { FactoryGirl.create(:logger_style) }
    let!(:logger_style_name1) {
      FactoryGirl.create(:logger_style_name, logger_name: FactoryGirl.create(:logger_name, name: 'Name1'),
                                             logger_level: FactoryGirl.create(:logger_level, level: 'Level1'),
                                             logger_style_id: logger_style.id)
    }
    let!(:logger_style_name2) {
      FactoryGirl.create(:logger_style_name, logger_name: FactoryGirl.create(:logger_name, name: 'Name2'),
                                             logger_level: FactoryGirl.create(:logger_level, level: 'Level2'),
                                             logger_style_id: logger_style.id)
    }

    # Mass-assignment
    [:name,
     :note,
     :logger_style_names_attributes].each do |a|
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
    it { should have_many(:logger_names) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }

    describe "#check_logger_style_names_attributes" do
      let(:error_message) { {
        logger_name_id: ['should be an uniqueness']
      } }

      before do
        logger_style_name2.logger_name_id = logger_style_name1.logger_name_id
        logger_style.logger_style_names << logger_style_name1
        logger_style.logger_style_names << logger_style_name2
        logger_style.check_logger_style_names_attributes
      end

      it "add errors to logger style" do
        logger_style.errors.messages.should == error_message
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#_logger_names" do
      before do
        logger_style.logger_style_names << logger_style_name1
        logger_style.logger_style_names << logger_style_name2
      end

      it "return comma separated logger names" do
        logger_style._logger_names.should == 'Name1, Name2'
      end
    end

    describe "#logger_levels" do
      before do
        logger_style.logger_style_names << logger_style_name1
        logger_style.logger_style_names << logger_style_name2
      end

      it "return comma separated logger levels" do
        logger_style.logger_levels.should == 'Level1, Level2'
      end
    end


  end
end
