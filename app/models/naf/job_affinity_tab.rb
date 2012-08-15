module Naf
  class JobAffinityTab < NafBase
<<<<<<< HEAD
=======

>>>>>>> f5c762858b03bd3a3d26df7525f21b1380fb9505
    validates :job_id, :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :job_id, :message => "has already been taken for this job"

<<<<<<< HEAD
    belongs_to :job, :class_name => '::Naf::Job'
    belongs_to :affinity, :class_name => '::Naf::Affinity'

    delegate :affinity_name, :affinity_classification_name, :to => :affinity

    attr_accessible :job_id, :affinity_id
=======
    belongs_to :job, :class_name => "::Naf::Job"
    belongs_to :affinity, :class_name => "::Naf::Affinity"

    delegate :title, :script_type_name, :command, :to => :job
    delegate :affinity_name, :to => :affinity

    delegate :affinity_classification_name, :to => :affinity

    attr_accessible :job_id, :affinity_id

>>>>>>> f5c762858b03bd3a3d26df7525f21b1380fb9505
  end
end
