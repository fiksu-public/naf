require 'spec_helper'

module Naf
  describe ApplicationScheduleAffinityTab do
    let!(:tab) { FactoryGirl.create(:normal_app_schedule_affinity_tab) }

    # Mass-assignment
    [:application_schedule_id,
     :affinity_id,
     :affinity_parameter].each do |a|
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
    it { should belong_to(:affinity) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_schedule_id) }
    it { should validate_presence_of(:affinity_id) }

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regard to delegation" do
      context "to affinity" do
        let!(:affinity) { tab.affinity }

        it "should delegate affinity name" do
          affinity.should_receive(:affinity_name)
          tab.affinity_name
        end

        it "should delegate affinity_classification_name" do
          affinity.should_receive(:affinity_classification_name)
          tab.affinity_classification_name
        end
      end

      context "to application schedule" do
        let(:schedule) { tab.application_schedule }

        it "should call the title method" do
          schedule.should_receive(:title)
          tab.script_title
        end
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#script_title" do
      it "return the application schedule title" do
        tab.application_schedule.application.title = 'App Schedule 1'
        tab.script_title.should == 'App Schedule 1'
      end
    end

    describe "#application" do
      it "return the application when present" do
        tab.application.should == tab.application_schedule.application
      end

      it "return nil when application not present" do
        tab.application_schedule.application = nil
        tab.application.should == nil
      end
    end

  end
end
