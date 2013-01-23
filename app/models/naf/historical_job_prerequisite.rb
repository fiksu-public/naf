module Naf
  class HistoricalJobPrerequisite < ::Naf::ByHistoricalJobId
    belongs_to :prerequisite_historical_job, :class_name => "::Naf::HistoricalJob"

    attr_accessible :prerequisite_historical_job_id
  end
end
