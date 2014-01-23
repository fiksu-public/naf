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
     :application_run_group_limit,
     :application_schedule_prerequisites_attributes,
     :enqueue_backlogs,
     :run_interval_style_id].each do |a|
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
    it { should belong_to(:run_interval_style) }
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

    let!(:time) { Time.zone.now.beginning_of_day }

    describe "#exact_schedules" do
      let!(:job) { FactoryGirl.create(:finished_job) }
      it "return schedule when it is ready" do
        ::Naf::ApplicationSchedule.exact_schedules(time, {}, {}).should == [schedule]
      end

      it "return no schedules when application has not finished running" do
        apps = { schedule.application_id => job }
        ::Naf::ApplicationSchedule.exact_schedules(time, apps, {}).should == []
      end

      it "return no schedules when interval time has not passed" do
        apps = { schedule.application_id => job }
        schedule.run_interval = 20
        ::Naf::ApplicationSchedule.exact_schedules(time, {}, apps).should == []
      end

      it "return no schedules when it is not time to run the application" do
        time = Time.zone.now
        ::Naf::ApplicationSchedule.exact_schedules(time, {}, {}).should == []
      end
    end

    describe "#relative_schedules" do
      let!(:job) { FactoryGirl.create(:finished_job) }
      it "return schedule when it is ready" do
        schedule.run_interval_style.name = 'after previous run'
        schedule.run_interval_style.save

        ::Naf::ApplicationSchedule.relative_schedules(time, {}, {}).should == [schedule]
      end

      it "return no schedules when application has not finished running" do
        apps = { schedule.application_id => job }
        ::Naf::ApplicationSchedule.relative_schedules(time, apps, {}).should == []
      end

      it "return no schedules when interval time has not passed" do
        apps = { schedule.application_id => job }
        schedule.run_interval = 20
        ::Naf::ApplicationSchedule.relative_schedules(time, {}, apps).should == []
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
          "\"App1\", start at: 00:00>"
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

  end
end
