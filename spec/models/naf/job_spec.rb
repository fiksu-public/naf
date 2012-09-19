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

    context "with regard to queuing from an application_schedule" do
      
      context "a new queued job should get from an application_schedule" do

        let(:app_schedule_for_canary) {
          tab = FactoryGirl.create(:canary_app_schedule_affinity_tab)
          tab.application_schedule
        }
        
        before(:all) {
          ::Naf::Job.delete_all
          ::Naf::JobAffinityTab.delete_all
          ::Naf::ApplicationSchedule.destroy_all
        }

        it "affinities" do
          ::Naf::Job.queue_application_schedule(app_schedule_for_canary)
          ::Naf::Job.first.job_affinity_tabs.map(&:affinity_id).should eql(app_schedule_for_canary.application_schedule_affinity_tabs.map(&:affinity_id))
        end


      end

    end

    context "with regard to fetching the next job" do
      let(:normal_slot)             { FactoryGirl.create(:normal_machine_affinity_slot, :machine => FactoryGirl.create(:machine)) }
      let(:required_perennial_slot) { FactoryGirl.create(:required_perennial_slot, :machine => FactoryGirl.create(:machine_two)) }

      let(:normal_machine)          { normal_slot.machine }
      let(:perennial_machine)       { required_perennial_slot.machine }

      let(:normal_tab)    { FactoryGirl.create(:normal_job_affinity_tab) }
      let(:perennial_tab) { FactoryGirl.create(:perennial_job_affinity_tab) }

      let(:normal_job)    { normal_tab.job    }
      let(:perennial_job) { perennial_tab.job }

      before(:all) do 
        ::Naf::Job.delete_all
      end

      before(:each) do
        ::Naf::MachineAffinitySlot.delete_all
        required_perennial_slot.required.should be_true
        normal_slot.required.should be_false
      end

      context "handling single affinities" do

        it "should skip over jobs that don't have the affinity a machine requires" do
          first_job, second_job = job, perennial_job
          first_job.should_not eql(second_job)
          first_job.job_affinity_tabs.should be_empty
          Job.possible_jobs.first.should eql(first_job)
          # perennial_machine skips job with no perennial affinity
          Job.fetch_next_job(perennial_machine).should eql(second_job)
        end

        it "should skip over jobs that the machine doesn't have an affinity for" do
          first_job, second_job = perennial_job, normal_job
          first_job.should_not eql(second_job)
          Job.possible_jobs.first.should eql(first_job)
          Job.fetch_next_job(normal_machine).should eql(second_job)
        end

      end
      
      context "handling multiple affinities" do
        let(:canary_machine) {
          slot = FactoryGirl.create(:canary_slot, :machine => FactoryGirl.create(:machine))
          slot.machine
        }
        let(:canary_job) { 
          tab = FactoryGirl.create(:canary_job_affinity_tab)
          tab.job
        }
        let(:canary_perennial_machine) { 
          slot_one = FactoryGirl.create(:required_canary_slot,    :machine => FactoryGirl.create(:machine_two))
          slot_two = FactoryGirl.create(:required_perennial_slot, :machine => FactoryGirl.create(:machine_two))
          slot_two.machine
        }
        let(:canary_perennial_job) {
          first_tab  = FactoryGirl.create(:canary_job_affinity_tab)
          second_tab = FactoryGirl.create(:perennial_job_affinity_tab, :job => first_tab.job)
          second_tab.job
        }
        
        before(:each) { ::Naf::MachineAffinitySlot.delete_all }

        it "should skip over jobs that don't have one of the required affinities for a machine" do
          first_job, second_job = canary_job, canary_perennial_job
          first_job.should_not eql(second_job)
          Job.possible_jobs.first.should eql(first_job)
          Job.fetch_next_job(canary_perennial_machine).should eql(second_job)
        end
        
        it "should skip over jobs that the machine doesn't have one affinity for" do
          first_job, second_job = canary_perennial_job, canary_job
          first_job.should_not eql(second_job)
          Job.possible_jobs.first.should eql(first_job)
          Job.fetch_next_job(canary_machine).should eql(second_job)
        end
        
      end

      
    end

  end
end
