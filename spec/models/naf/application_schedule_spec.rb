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

    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:application_run_group_restriction) }
    it { is_expected.to belong_to(:run_interval_style) }
    it { is_expected.to have_many(:application_schedule_affinity_tabs) }
    it { is_expected.to have_many(:affinities) }
    it { is_expected.to have_many(:application_schedule_prerequisites) }
    it { is_expected.to have_many(:prerequisites) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:application_run_group_restriction_id) }

    [-2147483647, 2147483646, 0].each do |v|
      it { is_expected.to allow_value(v).for(:priority) }
    end

    [-2147483648, 2147483647, 1.0, nil].each do |v|
      it { is_expected.not_to allow_value(v).for(:priority) }
    end

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regards to delegation" do
      it "should delegate the title method" do
        expect(schedule.application).to receive(:title)
        schedule.title
      end

      it "should delegate the application_run_group_restriction_name method" do
        expect(schedule.application_run_group_restriction).
          to receive(:application_run_group_restriction_name)
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
        expect(::Naf::ApplicationSchedule.exact_schedules(time, {}, {})).to eq([schedule])
      end

      it "return no schedules when application has not finished running" do
        apps = { schedule.id => job }
        expect(::Naf::ApplicationSchedule.exact_schedules(time, apps, {})).to eq([])
      end

      it "return no schedules when interval time has not passed" do
        apps = { schedule.id => job }
        schedule.run_interval = 20
        expect(::Naf::ApplicationSchedule.exact_schedules(time, {}, apps)).to eq([])
      end

      it "return no schedules when it is not time to run the application" do
        time = Time.zone.now
        expect(::Naf::ApplicationSchedule.exact_schedules(time, {}, {})).to eq([])
      end

      it "return no schedules when application is deleted" do
        schedule.application.deleted = true
        schedule.application.save!
        expect(::Naf::ApplicationSchedule.exact_schedules(time, {}, {})).to eq([])
      end
    end

    describe "#relative_schedules" do
      let!(:job) { FactoryGirl.create(:finished_job) }
      it "return schedule when it is ready" do
        schedule.run_interval_style.name = 'after previous run'
        schedule.run_interval_style.save

        expect(::Naf::ApplicationSchedule.relative_schedules(time, {}, {})).to eq([schedule])
      end

      it "return no schedules when application has not finished running" do
        apps = { schedule.application_id => job }
        expect(::Naf::ApplicationSchedule.relative_schedules(time, apps, {})).to eq([])
      end

      it "return no schedules when interval time has not passed" do
        apps = { schedule.application_id => job }
        schedule.run_interval = 20
        expect(::Naf::ApplicationSchedule.relative_schedules(time, {}, apps)).to eq([])
      end

      it "return no schedules when application is deleted" do
        schedule.application.deleted = true
        schedule.application.save!
        expect(::Naf::ApplicationSchedule.exact_schedules(time, {}, {})).to eq([])
      end
    end

    describe "#constant_schedules" do
      it "return schedule when it is ready" do
        schedule.run_interval_style.name = 'keep running'
        schedule.run_interval_style.save!

        expect(::Naf::ApplicationSchedule.constant_schedules).to eq([schedule])
      end

      it "return no schedules when application is deleted" do
        schedule.application.deleted = true
        schedule.application.save!
        expect(::Naf::ApplicationSchedule.constant_schedules).to eq([])
      end

      it "return no schedules when schedule is disabled" do
        schedule.enabled = false
        schedule.save!
        expect(::Naf::ApplicationSchedule.constant_schedules).to eq([])
      end

      it "return no schdules when run interval style is not keep running" do
        expect(::Naf::ApplicationSchedule.constant_schedules).to eq([])
      end
    end

    describe "#enabled" do
      it "return empty array when schedule is disabled" do
        schedule.enabled = false
        schedule.save!
        expect(::Naf::ApplicationSchedule.enabled).to eq([])
      end

      it "return array with schedule when schedule is enabled" do
        expect(::Naf::ApplicationSchedule.enabled).to eq([schedule])
      end
    end

    describe "#application_not_deleted" do
      it "return empty array when application is deleted" do
        schedule.application.deleted = true
        schedule.application.save!
        expect(::Naf::ApplicationSchedule.application_not_deleted).to eq([])
      end

      it "return array with schedule when application is not deleted" do
        expect(::Naf::ApplicationSchedule.application_not_deleted).to eq([schedule])
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
        expect(schedule.to_s).to eq("::Naf::ApplicationSchedule<ENABLED, id: #{schedule.id}, " +
          "\"App1\", #{::Logical::Naf::ApplicationSchedule.new(schedule).display}>")
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
        expect(schedule.errors.messages).to eq(error_messages)
      end
    end

  end
end
