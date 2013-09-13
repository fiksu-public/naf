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
     :application_schedule,
     :application_schedule_attributes].each do |a|
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

    it { should belong_to(:application_type) }
    it { should have_one(:application_schedule) }
    it { should have_many(:historical_jobs) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_type_id) }
    it { should validate_presence_of(:command) }
    it { should validate_presence_of(:title) }
    it { should validate_uniqueness_of(:title) }
    it { should validate_uniqueness_of(:short_name) }

    ['', 'aa', 'aA', 'Aa', 'AA', '_a', 'a1', 'A1', '_9'].each do |v|
      it { should allow_value(v).for(:short_name) }
    end

    ['1_', '3A', '9a'].each do |v|
      it { should_not allow_value(v).for(:short_name) }
    end

    context "upon creation" do
      let(:app_base) { FactoryGirl.build(:application_base, command: "::Naf::HistoricalJob.test hello_world",
                                                            title: "Test Hello World") }
      let(:incomplete_app_base) { FactoryGirl.build( :application_base) }

      it "should save with a command and title specified" do
        app_base.save.should be_true
      end

      it "should not save without a command or a title" do
        incomplete_app_base.save.should_not be_true
      end

      context "with regard to the title" do
        it "should not save when another title is taken" do
          app_2 = FactoryGirl.build(:application, title: app.title)
          app_2.save.should_not be_true
          app_2.should have(1).error_on(:title)
        end
      end
    end

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    context "with regard to delegation" do
      let(:application_type) { app.application_type }

      it "should delegate the script_type_name" do
        application_type.should_receive(:script_type_name)
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
        app.to_s.should == "::Naf::Application<id: #{app.id}, App1>"
      end
    end

    describe "#last_queued_job" do
      it "return correct queued job" do
        queued_job1 = FactoryGirl.create(:queued_job, application_id: app.id)
        queued_job1.historical_job.update_attributes!(application_id: app.id)
        queued_job2 = FactoryGirl.create(:queued_job, application_id: app.id)
        queued_job2.historical_job.update_attributes!(application_id: app.id)

        app.last_queued_job.should == queued_job2.historical_job
      end

      it "return nil when there are no jobs" do
        app.last_queued_job.should == nil
      end
    end

    describe "#short_name_if_it_exist" do
      it "return app's short_name" do
        app.update_attributes!(short_name: 'App1')
        app.short_name_if_it_exist.should == 'App1'
      end

      it "return app's title" do
        app.short_name = nil
        app.update_attributes!(title: 'Application 1')
        app.short_name_if_it_exist.should == 'Application 1'
      end
    end

  end
end
