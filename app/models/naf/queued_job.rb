module Naf
  class QueuedJob < NafBase
    # Protect from mass-assignment issue
    attr_accessible :application_id,
                    :application_type_id,
                    :command,
                    :application_run_group_restriction_id,
                    :application_run_group_name,
                    :application_run_group_limit,
                    :priority,
                    :historical_job

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :historical_job,
      class_name: "::Naf::HistoricalJob",
      foreign_key: :id
    belongs_to :application,
      class_name: "::Naf::Application"
    belongs_to :application_type,
      class_name: '::Naf::ApplicationType'
    belongs_to :application_run_group_restriction,
      class_name: "::Naf::ApplicationRunGroupRestriction"

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :application_type_id,
              :command,
              :application_run_group_restriction_id,
              :priority, presence: true

    #-------------------------
    # *** Class Methods ***
    #+++++++++++++++++++++++++

    def self.order_by_priority
      order("priority, created_at")
    end

    def self.exclude_run_group_names(names)
      if names.present?
        where("application_run_group_name NOT IN (?)", names)
      else
        where({})
      end
    end

    def self.runnable_by_machine(machine)
      where("NOT EXISTS (
        SELECT 1
        FROM naf.historical_job_affinity_tabs AS t
        WHERE t.historical_job_id = naf.queued_jobs.id AND
          NOT EXISTS (
            SELECT 1
            FROM naf.machine_affinity_slots AS s
            WHERE s.affinity_id = t.affinity_id AND
              s.machine_id = #{machine.id}
          )
        )"
      )
    end

    def self.prerequisites_finished
      where("NOT EXISTS (
        SELECT 1
        FROM naf.historical_job_prerequisites AS p
        WHERE p.historical_job_id = naf.queued_jobs.id AND
          EXISTS (
            SELECT 1
            FROM naf.historical_jobs AS j
            WHERE p.prerequisite_historical_job_id = j.id AND
              j.finished_at IS NULL
          )
        )"
      )
    end

  end
end
