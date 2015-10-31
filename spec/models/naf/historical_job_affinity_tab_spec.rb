require 'spec_helper'

module Naf
  describe HistoricalJobAffinityTab do
    let!(:historical_job_affinity_tab) { FactoryGirl.create(:normal_job_affinity_tab) }

    # Mass-assignment
    [:affinity_id,
     :historical_job_id,
     :historical_job,
     :affinity_parameter].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:affinity) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:affinity_id) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#job" do
      let(:job) { FactoryGirl.create(:job) }

      it "return the correct job" do
        historical_job_affinity_tab.historical_job_id = job.id
        expect(historical_job_affinity_tab.job).to eq(job)
      end
    end

    describe "#script_type_name" do
      it "return the correct name" do
        expect(historical_job_affinity_tab.script_type_name).to eq("rails")
      end
    end

    describe "#command" do
      it "return the correct command" do
        expect(historical_job_affinity_tab.command).
          to eq("::Naf::HistoricalJob.test hello world")
      end
    end

  end
end
