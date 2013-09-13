require 'spec_helper'

module Naf
  describe ApplicationSchedule do
    let!(:schedule) { FactoryGirl.create(:schedule) }

    # Mass-assignment
    [:application_id,
     :application_run_group_restriction_id,
     :application_run_group_name,
     :run_interval,
     :priority,
     :visible,
     :enabled,
     :run_start_minute,
     :application_run_group_limit,
     :application_schedule_prerequisites_attributes,
     :enqueue_backlogs].each do |a|
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

    it { should belong_to(:application) }
    it { should belong_to(:application_run_group_restriction) }
    it { should have_many(:application_schedule_affinity_tabs) }
    it { should have_many(:affinities) }
    it { should have_many(:application_schedule_prerequisites) }
    it { should have_many(:prerequisites) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_run_group_restriction_id) }

    [-2147483647, 2147483646, 0].each do |v|
      it { should allow_value(v).for(:priority) }
    end

    [-2147483648, 2147483647, 1.0, nil].each do |v|
      it { should_not allow_value(v).for(:priority) }
    end

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regards to delegation" do
      it "should delegate the title method" do
        schedule.application.should_receive(:title)
        schedule.title
      end

      it "should delegate the application_run_group_restriction_name method" do
        schedule.application_run_group_restriction.
          should_receive(:application_run_group_restriction_name)
        schedule.application_run_group_restriction_name
      end
    end

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#exact_schedules" do
      it "return schedule when run_start_minute is set" do
        schedule.update_attributes!(run_start_minute: 1, run_interval: nil)
        ::Naf::ApplicationSchedule.exact_schedules.should == [schedule]
      end

      it "return no schedules when run_start_minute is not set" do
        schedule.update_attributes!(run_start_minute: nil, run_interval: nil)
        ::Naf::ApplicationSchedule.exact_schedules.should == []
      end
    end

    describe "#relative_schedules" do
      it "return schedule when run_interval is set" do
        schedule.update_attributes!(run_interval: 60)
        ::Naf::ApplicationSchedule.relative_schedules.should == [schedule]
      end

      it "return no schedules when run_interval is not set" do
        schedule.update_attributes!(run_interval: nil)
        ::Naf::ApplicationSchedule.relative_schedules.should == []
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#to_s" do
      before do
        schedule.application.title = 'App1'
        schedule.save!
      end

      it "return correct parsing of app" do
        schedule.to_s.should == "::Naf::ApplicationSchedule<ENABLED, id: #{schedule.id}, " +
          "\"App1\", start every: 1 minutes>"
      end
    end

    describe "#visible_enabled_check" do
      let(:error_messages) { {
        visible: ['must be true, or set enabled to false'],
        enabled: ['must be false, if visible is set to false']
      } }

      before do
        schedule.visible = false
        schedule.visible_enabled_check
      end

      it "add errors to schedule" do
        schedule.errors.messages.should == error_messages
      end
    end

    describe "#enabled_application_id_unique" do
      let(:error_message) { {
        application_id: ['is enabled and has already been taken']
      } }

      it "return nil if enabled is false" do
        schedule.enabled = false
        schedule.enabled_application_id_unique.should == nil
      end

      it "return nil if enabled is false" do
        schedule2 = FactoryGirl.create(:schedule)
        schedule2.application_id = schedule.application_id
        schedule2.enabled_application_id_unique

        schedule2.errors.messages.should == error_message
      end
    end

    describe "#run_interval_at_time_check" do
      let(:error_messages) { {
        run_interval: ['or Run start minute must be nil'],
        run_start_minute: ['or Run interval must be nil']
      } }

      before do
        schedule.run_start_minute = 1
        schedule.run_interval_at_time_check
      end

      it "add errors to schedule" do
        schedule.errors.messages.should == error_messages
      end
    end

  end
end
