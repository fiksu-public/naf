module Naf
  class HistoricalJobAffinityTab < ::Naf::ByHistoricalJobId
    validates :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :historical_job_id, :message => "has already been taken for this job"

    belongs_to :affinity, :class_name => "::Naf::Affinity"

    delegate :affinity_name, :affinity_classification_name, :affinity_short_name, :to => :affinity

    attr_accessible :affinity_id

    partitioned do |partition|
      partition.foreign_key :affinity_id, full_table_name_prefix + "affinities"
    end

    def job
      return ::Naf::HistoricalJob.
        from_partition(id).
        where(:id => historical_job_id).first
    end

    def script_type_name
      job.script_type_name
    end

    def command
      job.command
    end
  end
end
