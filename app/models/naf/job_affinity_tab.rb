module Naf
  class JobAffinityTab < ::Naf::ByJobId
    validates :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :job_id, :message => "has already been taken for this job"

    belongs_to :affinity, :class_name => "::Naf::Affinity"

    delegate :title, :script_type_name, :command, :to => :job

    delegate :affinity_name, :affinity_classification_name, :short_name_if_it_exist, :to => :affinity

    attr_accessible :affinity_id

    partitioned do |partition|
      partition.foreign_key :affinity_id, full_table_name_prefix + "affinities"
    end
  end
end
