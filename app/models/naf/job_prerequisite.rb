module Naf
  class JobPrerequisite < ::Naf::ByJobId
    belongs_to :prerequisite_job, :class_name => "::Naf::Job"

    attr_accessible :prerequisite_job_id, :created_at
  end
end
