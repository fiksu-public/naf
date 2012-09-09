module Naf
  class JobPrerequisite < ::Naf::ByJobCreatedAt
    attr_accessible :job_id, :job_created_at, :prerequisite_job_id
  end
end
