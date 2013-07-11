require 'spec_helper'

module Naf
  describe HistoricalJob do
    let(:historical_job) { FactoryGirl.create(:job) }

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
     :log_level].each do |a|
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
    it { should have_many(:historical_job_prerequisites) }
    it { should have_many(:prerequisites) }
    it { should have_many(:historical_job_affinity_tabs) }
    it { should have_many(:historical_job_affinities) }

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

    context "when it is newly created" do
      it "should find the job by run group" do
        HistoricalJob.where(application_run_group_name: historical_job.application_run_group_name).
          should include(historical_job)
      end
    end

    context "With regard to method calls" do
      it "should delegate a method to application type" do
        historical_job.script_type_name.should == 'rails'
      end
    end

    context "when the job is picked" do
      let(:picked_job) { FactoryGirl.create(:job_picked_by_machine) }
      it "should not be found by the started scope" do
        picked_job_id = picked_job.id
        HistoricalJob.where("started_at is not null").map(&:id).should_not include(picked_job_id)
      end
    end

    context "when the job is stale" do
      let(:stale_job) { FactoryGirl.create(:stale_job) }
      it "should not be found by queued_between scope" do
        stale_job_id = stale_job.id
        HistoricalJob.queued_between(Time.zone.now - Naf::HistoricalJob::JOB_STALE_TIME, Time.zone.now).
          map(&:id).should_not include(stale_job_id)
      end
    end

    context "when it is running" do
      let(:running_job) { FactoryGirl.create(:running_job) }

      it "should be found by the started scope" do
        running_job_id = running_job.id
        HistoricalJob.where("started_at is not null").map(&:id).should include(running_job_id)
      end

      it "should not be found by not_started scope" do
        HistoricalJob.where(started_at: nil).should_not include(running_job)
      end
    end

    context "when it is finished" do
      let(:finished_job) { FactoryGirl.create(:finished_job) }

      it "should be found by the finished scope" do
        HistoricalJob.finished.should include(finished_job)
      end

      it "should be found by the started scope" do
        HistoricalJob.where("started_at is not null").should include(finished_job)
      end
    end

  end
end
