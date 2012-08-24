require 'spec_helper'

module Naf
  describe Job do
    
    let(:job)         { FactoryGirl.create(:job) }
    let(:running_job) { FactoryGirl.create(:running_job) }
    
    context "With regard to method calls" do
      it "should delegate a method to application type" do
        job.script_type_name.should == 'rails'
      end
    end

    context "when it is running" do
      it "should be found by the started scope" do
        running_job_id = running_job.id
        Job.started.map(&:id).should include(running_job_id)
      end
    end

    

  end
end
