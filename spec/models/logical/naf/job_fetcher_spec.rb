require 'spec_helper'


module Logical
  module Naf
    describe JobFetcher do
      
      context "with regard to fetching the next job" do

        let(:job)         { FactoryGirl.create(:job) }

        let(:normal_slot)             { FactoryGirl.create(:normal_machine_affinity_slot, :machine => FactoryGirl.create(:machine)) }
        let(:required_perennial_slot) { FactoryGirl.create(:required_perennial_slot, :machine => FactoryGirl.create(:machine_two)) }
        
        let(:normal_machine)          { normal_slot.machine }
        let(:perennial_machine)       { required_perennial_slot.machine }
        
        let(:normal_tab)    { FactoryGirl.create(:normal_job_affinity_tab) }
        let(:perennial_tab) { FactoryGirl.create(:perennial_job_affinity_tab) }
        
        let(:normal_job)    { normal_tab.job    }
        let(:perennial_job) { perennial_tab.job }


        let(:perennial_job_fetcher) { JobFetcher.new(perennial_machine) }
        let(:normal_job_fetcher) { JobFetcher.new(normal_machine) }
        
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
            ::Naf::Job.possible_jobs.first.should eql(first_job)
            # perennial_machine skips job with no perennial affinity
            perennial_job_fetcher.fetch_next_job.should eql(second_job)
          end
          
          it "should skip over jobs that the machine doesn't have an affinity for" do
            first_job, second_job = perennial_job, normal_job
            first_job.should_not eql(second_job)
            ::Naf::Job.possible_jobs.first.should eql(first_job)
            normal_job_fetcher.fetch_next_job.should eql(second_job)
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
          
          let(:canary_job_fetcher) { JobFetcher.new(canary_machine) }
          let(:canary_perennial_job_fetcher) { JobFetcher.new(canary_perennial_machine) }

          before(:each) { ::Naf::MachineAffinitySlot.delete_all }
          
          it "should skip over jobs that don't have one of the required affinities for a machine" do
            first_job, second_job = canary_job, canary_perennial_job
            first_job.should_not eql(second_job)
            ::Naf::Job.possible_jobs.first.should eql(first_job)
            canary_perennial_job_fetcher.fetch_next_job.should eql(second_job)
          end
          
          it "should skip over jobs that the machine doesn't have one affinity for" do
            first_job, second_job = canary_perennial_job, canary_job
            first_job.should_not eql(second_job)
            ::Naf::Job.possible_jobs.first.should eql(first_job)
            canary_job_fetcher.fetch_next_job.should eql(second_job)
          end
          
        end
        
        # TODO: Fill in these tests
        # It's important that fetching jobs followings the run group restrictions
        
        context "handling run group restrictions" do
          
          it "should not limit running jobs in a run group with no limit restriction"
          
          it "should limit running jobs in a run group per machine"
          
          it "should limit running jobs in a run group per all machines"
          
        end
        
      end
    end
  end
end
