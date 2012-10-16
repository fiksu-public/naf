module Naf
  class JobCreatedAt < ::Naf::ByJobCreatedAt
    belongs_to :job, :class_name => "::Naf::Job"

    attr_accessible :job_id, :job_created_at
  end
end
