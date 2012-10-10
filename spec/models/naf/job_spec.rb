require 'spec_helper'

module Naf
  describe Job do
    
    
    let(:job)         { FactoryGirl.create(:job) }

    context "when it is newly created" do
      it "should be found in the possible_jobs scope" do
        job_id = job.id
        Job.possible_jobs.map(&:id).should include(job_id)
      end
      it "should find the job by run group" do
        Job.in_run_group(job.application_run_group_name).should include(job)
      end
    end

    
    context "With regard to method calls" do
      it "should delegate a method to application type" do
        job.script_type_name.should == 'rails'
      end
    end

    context "when the job is picked" do
      let(:picked_job) { FactoryGirl.create(:job_picked_by_machine) }
      it "should not be found by the started scope" do
        picked_job_id = picked_job.id
        Job.started.map(&:id).should_not include(picked_job_id)
      end
    end

    context "when the job is stale" do
      let(:stale_job) { FactoryGirl.create(:stale_job) }
      it "should not be found by recently_queued scope" do
        stale_job_id = stale_job.id
        Job.recently_queued.map(&:id).should_not include(stale_job_id)
      end
    end

    context "when it is running" do
      let(:running_job) { FactoryGirl.create(:running_job) }
      it "should be found by the started scope" do
        running_job_id = running_job.id
        Job.started.map(&:id).should include(running_job_id)
      end
      it "should not be found by not_started scope" do
        Job.not_started.should_not include(running_job)
      end
    end

    context "when it is finished" do
      let(:finished_job) { FactoryGirl.create(:finished_job) }
      it "should be found by the finished scope" do
        Job.finished.should include(finished_job)
      end
      it "should be found by the started scope" do
        Job.started.should include(finished_job)
      end
    end

  end
end
