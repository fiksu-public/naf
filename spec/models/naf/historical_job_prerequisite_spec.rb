require 'spec_helper'

module Naf
  describe HistoricalJobPrerequisite do

    # Mass-assignment
    [:historical_job_id,
     :prerequisite_historical_job_id].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should belong_to(:historical_job) }
    it { should belong_to(:prerequisite_historical_job) }

  end
end