require 'spec_helper'

module Logical
  module Naf
    describe JobFetcher do
      let(:job) { FactoryGirl.create(:job) }
      let(:normal_slot) { FactoryGirl.create(:normal_machine_affinity_slot, machine: FactoryGirl.create(:machine)) }
      let(:required_perennial_slot) { FactoryGirl.create(:required_perennial_slot, machine: FactoryGirl.create(:machine_two)) }
      let(:normal_machine) { normal_slot.machine }
      let(:perennial_machine) { required_perennial_slot.machine }
      let(:normal_tab) { FactoryGirl.create(:normal_job_affinity_tab) }
      let(:perennial_tab) { FactoryGirl.create(:perennial_job_affinity_tab) }
      let(:normal_job) { normal_tab.job }
      let(:perennial_job) { perennial_tab.job }
      let(:perennial_job_fetcher) { JobFetcher.new(perennial_machine) }
      let(:normal_job_fetcher) { JobFetcher.new(normal_machine) }

      before(:all) do
        ::Naf::HistoricalJob.delete_all
      end

      before do
        ::Naf::MachineAffinitySlot.delete_all
        FactoryGirl.create(:affinity, id: 4, affinity_name: 'cpus')
        FactoryGirl.create(:affinity, id: 5, affinity_name: 'memory')
      end

      #----------------------------
      # ***   Shared Examples   ***
      #++++++++++++++++++++++++++++

      shared_examples "inserts machine affinity slots correctly" do
        it { expect(required_perennial_slot.required).to be_truthy }
        it { expect(normal_slot.required).to be_falsey }
      end

      shared_examples "fetches next job correctly" do
        it "asserts next job is not equal to first job" do
          expect(first_job).not_to eq(second_job)
        end

        it "insert row correctly into historical_jobs" do
          expect(::Naf::HistoricalJob.queued_between(Time.zone.now - ::Naf::HistoricalJob::JOB_STALE_TIME, Time.zone.now).
            where(started_at: nil).order(:id).first).to eq(first_job)
        end

        it "return correctly next fetched job" do
          FactoryGirl.create(:queued_job, historical_job: second_job)
          expect(fetcher.fetch_next_job.historical_job).to eq(second_job)
        end
      end

      describe "single affinity" do
        context "jobs that don't have the affinity a machine requires" do
          before do
            job
            perennial_job
          end

          it "return 0 affinity tabs for first job" do
            expect(job.historical_job_affinity_tabs).to be_empty
          end

          it_should_behave_like "inserts machine affinity slots correctly"
          it_should_behave_like "fetches next job correctly" do
            let(:first_job) { job }
            let(:second_job) { perennial_job }
            let(:fetcher) { perennial_job_fetcher }
          end
        end

        context "jobs that the machine doesn't have an affinity for" do
          before do
            perennial_job
            normal_job
          end

          it_should_behave_like "inserts machine affinity slots correctly"
          it_should_behave_like "fetches next job correctly" do
            let(:first_job) { perennial_job }
            let(:second_job) { normal_job }
            let(:fetcher) { normal_job_fetcher }
          end
        end
      end

      describe "multiple affinities" do
        let(:canary_machine) {
          slot = FactoryGirl.create(:canary_slot, machine: FactoryGirl.create(:machine))
          slot.machine
        }
        let(:canary_job) {
          tab = FactoryGirl.create(:canary_job_affinity_tab)
          tab.job
        }
        let(:canary_perennial_machine) {
          slot_one = FactoryGirl.create(:required_canary_slot, machine: FactoryGirl.create(:machine_two))
          slot_two = FactoryGirl.create(:required_perennial_slot, machine: FactoryGirl.create(:machine_two))
          slot_two.machine
        }
        let(:canary_perennial_job) {
          first_tab  = FactoryGirl.create(:canary_job_affinity_tab)
          second_tab = FactoryGirl.create(:perennial_job_affinity_tab, historical_job: first_tab.job)
          second_tab.job
        }
        let(:canary_job_fetcher) { JobFetcher.new(canary_machine) }
        let(:canary_perennial_job_fetcher) { JobFetcher.new(canary_perennial_machine) }

        context "jobs that the machine doesn't have an affinity for" do
          before do
            canary_job
            canary_perennial_job
          end

          it_should_behave_like "inserts machine affinity slots correctly"
          it_should_behave_like "fetches next job correctly" do
            let(:first_job) { canary_job }
            let(:second_job) { canary_perennial_job }
            let(:fetcher) { canary_perennial_job_fetcher }
          end
        end

        context "jobs that the machine doesn't have one affinity for" do
          before do
            canary_perennial_job
            canary_job
          end

          it_should_behave_like "inserts machine affinity slots correctly"
          it_should_behave_like "fetches next job correctly" do
            let(:first_job) { canary_perennial_job }
            let(:second_job) { canary_job }
            let(:fetcher) { canary_job_fetcher }
          end
        end
      end
    end

  end
end
