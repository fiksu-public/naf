require 'spec_helper'

module Naf
  describe HistoricalJob do

    before(:all) do
      ::Naf::HistoricalJob.delete_all
    end

    let!(:historical_job) { FactoryGirl.create(:job) }

    # Mass-assignment
    [:application_id,
     :application_type_id,
     :command,
     :application_run_group_restriction_id,
     :application_run_group_name,
     :application_run_group_limit,
     :priority,
     :started_on_machine_id,
     :failed_to_start,
     :pid,
     :exit_status,
     :termination_signal,
     :state,
     :request_to_terminate,
     :marked_dead_by_machine_id,
     :log_level,
     :tags,
     :machine_runner_id].each do |a|
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
    it { should belong_to(:started_on_machine) }
    it { should belong_to(:marked_dead_by_machine) }
    it { should belong_to(:application) }
    it { should belong_to(:application_run_group_restriction) }
    it { should belong_to(:machine_runner) }
    it { should have_many(:historical_job_prerequisites) }
    it { should have_many(:prerequisites) }
    it { should have_many(:historical_job_affinity_tabs) }
    it { should have_many(:affinities) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_type_id) }
    it { should validate_presence_of(:command) }
    it { should validate_presence_of(:application_run_group_restriction_id) }

    [1, 100, 2147483646, ''].each do |v|
      it { should allow_value(v).for(:application_run_group_limit) }
    end

    [0, 2147483647, 1.1].each do |v|
      it { should_not allow_value(v).for(:application_run_group_limit) }
    end

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#full_table_name_prefix" do
      it "return the correct string" do
        ::Naf::HistoricalJob.full_table_name_prefix.should == 'naf.'
      end
    end

    describe "#queued_between" do
      before do
        FactoryGirl.create(:job, created_at: Time.zone.now - 5.minutes)
      end

      it "return the correct queued job" do
        ::Naf::HistoricalJob.queued_between(Time.zone.now - 1.minutes, Time.zone.now).
          should == [historical_job]
      end
    end

    describe "#canceled" do
      it "return jobs requested to terminate" do
        historical_job.update_attributes!(request_to_terminate: true)
        ::Naf::HistoricalJob.canceled.should == [historical_job]
      end

      it "return nil when no jobs have been requested to terminate" do
        ::Naf::HistoricalJob.canceled.should == []
      end
    end

    describe "#application_last_runs" do
      before do
        historical_job.update_attributes!(application_id: FactoryGirl.create(:application).id)
      end

      it "return job when it finished running" do
        historical_job.finished_at = Time.zone.now
        historical_job.save!
        ::Naf::HistoricalJob.application_last_runs.first.application.should == historical_job.application
      end

      it "return nil when job has not finished running" do
        ::Naf::HistoricalJob.application_last_runs.should == []
      end
    end

    describe "#application_last_queued" do
      let(:historical_job2) { FactoryGirl.create(:job) }
      before do
        application = FactoryGirl.create(:application)
        historical_job.update_attributes!(application_id: application.id)
        historical_job2.update_attributes!(application_id: application.id)
      end

      it "return correct application id" do
        ::Naf::HistoricalJob.application_last_queued.first.should == historical_job2
      end
    end

    describe "#finished" do
      it "return jobs that have finished running" do
        historical_job.finished_at = Time.zone.now
        historical_job.save!
        ::Naf::HistoricalJob.finished.should == [historical_job]
      end

      it "return jobs requested to terminate" do
        historical_job.update_attributes!(request_to_terminate: true)
        ::Naf::HistoricalJob.finished.should == [historical_job]
      end

      it "return nil when no jobs have been requested to terminate or have finished running" do
        ::Naf::HistoricalJob.finished.should == []
      end
    end

    describe "#queued_status" do
      let(:historical_job2) { FactoryGirl.create(:job, finished_at: Time.zone.now) }
      let(:historical_job3) { FactoryGirl.create(:job, started_at: Time.zone.now) }

      it "return correct jobs" do
        FactoryGirl.create(:job, request_to_terminate: true)
        ::Naf::HistoricalJob.queued_status.
          order(:id).should == [historical_job, historical_job2, historical_job3]
      end
    end

    describe "#running_status" do
      let(:historical_job2) { FactoryGirl.create(:job, finished_at: Time.zone.now) }

      it "return correct jobs" do
        historical_job.started_at = Time.zone.now
        historical_job.save!
        FactoryGirl.create(:job, request_to_terminate: true)

        ::Naf::HistoricalJob.running_status.
          order(:id).should == [historical_job, historical_job2]
      end
    end

    describe "#queued_with_waiting" do
      it "return correct jobs" do
        FactoryGirl.create(:job, request_to_terminate: true)
        ::Naf::HistoricalJob.queued_with_waiting.
          order(:id).should == [historical_job]
      end
    end

    describe "#errored" do
      let(:historical_job2) { FactoryGirl.create(:job, request_to_terminate: true) }
      let(:historical_job3) { FactoryGirl.create(:job, finished_at: Time.zone.now,
                                                       exit_status: 1) }

      it "return correct jobs" do
        ::Naf::HistoricalJob.errored.
          order(:id).should == [historical_job2, historical_job3]
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#to_s" do
      before do
        historical_job.update_attributes!(command: "puts 'hi'")
      end

      it "return correct parsing of app" do
        historical_job.to_s.should == "::Naf::HistoricalJob<QUEUED, id: #{historical_job.id}, \"puts \'hi\'\">"
      end
    end

    describe "#title" do
      it "return correct application title when present" do
        historical_job.application = FactoryGirl.create(:application, title: 'App1')
        historical_job.title.should == 'App1'
      end

      it "return nil when application not present" do
        historical_job.title.should == nil
      end
    end

    describe "#machine_started_on_server_name" do
      it "return correct machine server name when present" do
        historical_job.started_on_machine = FactoryGirl.create(:machine, server_name: 'Machine1')
        historical_job.machine_started_on_server_name.should == 'Machine1'
      end

      it "return nil when machine not present" do
        historical_job.machine_started_on_server_name.should == nil
      end
    end

    describe "#machine_started_on_server_address" do
      it "return correct machine server name when present" do
        historical_job.started_on_machine = FactoryGirl.create(:machine)
        historical_job.machine_started_on_server_address.should == '0.0.0.1'
      end

      it "return nil when machine not present" do
        historical_job.machine_started_on_server_address.should == nil
      end
    end

    describe "#historical_job_affinity_tabs" do
      it "return affinity tabs associated with historical_job" do
        affinity_tab = FactoryGirl.create(:normal_job_affinity_tab, historical_job: historical_job)
        historical_job.historical_job_affinity_tabs.should == [affinity_tab]
      end
    end

    describe "#job_affinities" do
      it "return affinities associated with historical_job" do
        affinity_tab = FactoryGirl.create(:normal_job_affinity_tab, historical_job: historical_job)
        historical_job.job_affinities.should == [affinity_tab.affinity]
      end
    end

    describe "#affinity_ids" do
      it "return affinities associated with historical_job" do
        affinity_tab = FactoryGirl.create(:normal_job_affinity_tab, historical_job: historical_job)
        historical_job.affinity_ids.should == [affinity_tab.affinity.id]
      end
    end

    describe "#historical_job_prerequisites" do
      it "return historical job prerequisites associated with historical_job" do
        historical_job_prerequesite = FactoryGirl.
          create(:historical_job_prerequesite, historical_job: historical_job,
                                               prerequisite_historical_job: FactoryGirl.create(:job))
        historical_job.historical_job_prerequisites.should == [historical_job_prerequesite]
      end
    end

    describe "#prerequisites" do
      it "return prerequisites associated with historical_job" do
        prerequisite = FactoryGirl.create(:job)
        historical_job_prerequesite = FactoryGirl.
          create(:historical_job_prerequesite, historical_job: historical_job,
                                               prerequisite_historical_job: prerequisite)
        historical_job.prerequisites.should == [prerequisite]
      end
    end

    describe "#verify_prerequisites" do
      it "not raise error when job is not in a prerequisite loop" do
        historical_job2 = FactoryGirl.create(:job)
        expect { historical_job.verify_prerequisites([historical_job2]) }.not_to raise_error
      end

      it "raise an error when job is in a prerequesite loop" do
        expect { historical_job.verify_prerequisites([historical_job]) }.to raise_error
      end
    end

    describe "#add_tags" do
      before do
        historical_job.tags = "{$pre-work}"
      end

      it "insert unique tag" do
        historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:work]])
        historical_job.tags.should == "{$pre-work,$work}"
      end

      it "not insert non-unique tag" do
        historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:pre_work]])
        historical_job.tags.should == "{$pre-work}"
      end
    end

    describe "#remove_tags" do
      before do
        historical_job.tags = "{$pre-work}"
      end

      it "remove existing tag" do
        historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:pre_work]])
        historical_job.tags.should == "{}"
      end

      it "not update tags when removing non-existing tag" do
        historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:work]])
        historical_job.tags.should == "{$pre-work}"
      end
    end

    describe "#remove_all_tags" do
      before do
        historical_job.tags = "{$pre-work}"
      end

      it "remove any existing tags" do
        historical_job.remove_all_tags
        historical_job.tags.should == "{}"
      end
    end

  end
end
