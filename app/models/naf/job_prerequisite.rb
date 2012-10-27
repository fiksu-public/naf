module Naf
  # XXX this should be by job_id % 10000 like job_affinity_tabs
  class JobPrerequisite < ::Naf::ByJobCreatedAt
    belongs_to :job, :class_name => "::Naf::Job"
    belongs_to :prerequisite_job, :class_name => "::Naf::Job"

    attr_accessible :job_id, :job_created_at, :prerequisite_job_id
  end
end
