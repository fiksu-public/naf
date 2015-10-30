require 'spec_helper'
module Naf
  describe Application do
    let!(:app) { FactoryGirl.create(:application) }

    # Mass-assignment
    [:title,
     :command,
     :application_type_id,
     :log_level,
     :short_name,
     :deleted,
     :application_schedules,
     :application_schedules_attributes].each do |a|
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

    it { is_expected.to belong_to(:application_type) }
    it { is_expected.to have_many(:application_schedules) }
    it { is_expected.to have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:application_type_id) }
    it { is_expected.to validate_presence_of(:command) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:title) }
    it { is_expected.to validate_uniqueness_of(:short_name) }

    ['', 'aa', 'aA', 'Aa', 'AA', '_a', 'a1', 'A1', '_9'].each do |v|
      it { is_expected.to allow_value(v).for(:short_name) }
    end

    ['1_', '3A', '9a'].each do |v|
      it { is_expected.not_to allow_value(v).for(:short_name) }
    end

    context "upon creation" do
      let(:app_base) { FactoryGirl.build(:application_base, command: "::Naf::HistoricalJob.test hello_world",
                                                            title: "Test Hello World") }
      let(:incomplete_app_base) { FactoryGirl.build( :application_base) }

      it "should save with a command and title specified" do
        expect(app_base.save).to be_truthy
      end

      it "should not save without a command or a title" do
        expect(incomplete_app_base.save).not_to be_truthy
      end

      context "with regard to the title" do
        it "should not save when another title is taken" do
          app_2 = FactoryGirl.build(:application, title: app.title)
          expect(app_2.save).not_to be_truthy
          expect(app_2.errors[:title].size).to eq 1
        end
      end
    end

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regard to delegation" do
      let(:application_type) { app.application_type }

      it "should delegate the script_type_name" do
        expect(application_type).to receive(:script_type_name)
        app.script_type_name
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#to_s" do
      before do
        app.update_attributes!(title: 'App1')
      end

      it "return correct parsing of app" do
        expect(app.to_s).to eq("::Naf::Application<id: #{app.id}, App1>")
      end
    end

    describe "#last_queued_job" do
      it "return correct queued job" do
        queued_job1 = FactoryGirl.create(:queued_job, application_id: app.id)
        queued_job1.historical_job.update_attributes!(application_id: app.id)
        queued_job2 = FactoryGirl.create(:queued_job, application_id: app.id)
        queued_job2.historical_job.update_attributes!(application_id: app.id)

        expect(app.last_queued_job).to eq(queued_job2.historical_job)
      end

      it "return nil when there are no jobs" do
        expect(app.last_queued_job).to eq(nil)
      end
    end

    describe "#short_name_if_it_exist" do
      it "return app's short_name" do
        app.update_attributes!(short_name: 'App1')
        expect(app.short_name_if_it_exist).to eq('App1')
      end

      it "return app's title" do
        app.short_name = nil
        app.update_attributes!(title: 'Application 1')
        expect(app.short_name_if_it_exist).to eq('Application 1')
      end
    end

  end
end
