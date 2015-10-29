require 'spec_helper'

module Naf
  describe HistoricalJobPrerequisite do

    # Mass-assignment
    [:historical_job_id,
     :prerequisite_historical_job_id].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to belong_to(:historical_job) }
    it { is_expected.to belong_to(:prerequisite_historical_job) }

  end
end