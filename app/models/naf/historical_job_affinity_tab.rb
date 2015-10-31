module Naf
  class HistoricalJobAffinityTab < ::Naf::ByHistoricalJobId
    # Protect from mass-assignment issue
    attr_accessible :affinity_id,
                    :historical_job_id,
                    :historical_job,
                    :affinity_parameter

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :affinity,
      class_name: "::Naf::Affinity"

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :affinity_id, presence: true,
                            uniqueness: {
                              scope: :historical_job_id,
                              message: "has already been taken for this job"
                            }

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :affinity_name,
             :affinity_classification_name,
             :affinity_short_name, to: :affinity

    #------------------
    # *** Partition ***
    #++++++++++++++++++

    partitioned do |partition|
      partition.foreign_key :affinity_id, ::Naf::Affinity.table_name
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def job
      ::Naf::HistoricalJob.
        from_partition(id).
        where(id: historical_job_id).
        order("id ASC").first
    end

    def script_type_name
      job.script_type_name
    end

    def command
      job.command
    end

  end
end
