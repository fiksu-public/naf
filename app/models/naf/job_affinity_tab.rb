module Naf
  class JobAffinityTab < ::Partitioned::ByForeignKey
    validates :job_id, :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :job_id, :message => "has already been taken for this job"

    belongs_to :job, :class_name => "::Naf::Job"
    belongs_to :affinity, :class_name => "::Naf::Affinity"

    delegate :title, :script_type_name, :command, :to => :job
    delegate :affinity_name, :to => :affinity

    delegate :affinity_classification_name, :to => :affinity

    attr_accessible :job_id, :affinity_id

    def self.partition_foreign_key
      return :job_id
    end

    def self.connection
      return ::Naf::NafBase.connection
    end

    def self.partition_table_size
      return ::Naf::Job.partition_table_size
    end

    partitioned do |partition|
      partition.index :id, :unique => true
    end
  end
end
