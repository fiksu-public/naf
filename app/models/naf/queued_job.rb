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

    def self.is_not_restricted_by_run_group(machine)
      sql = <<-SQL
      (
        #{Naf.schema_name}.queued_jobs.application_run_group_name is null OR
        #{Naf.schema_name}.queued_jobs.application_run_group_limit is null OR
        #{Naf.schema_name}.application_run_group_restrictions.application_run_group_restriction_name = 'no limit' OR
        (
          #{Naf.schema_name}.application_run_group_restrictions.application_run_group_restriction_name = 'limited per machine' AND
          (select
            count(*) < #{Naf.schema_name}.queued_jobs.application_run_group_limit
           from
             #{Naf.schema_name}.running_jobs as rj
           where
             rj.application_run_group_name = #{Naf.schema_name}.queued_jobs.application_run_group_name and
             rj.started_on_machine_id = #{machine.id})
        ) OR
        (
          application_run_group_restrictions.application_run_group_restriction_name = 'limited per all machines' AND
          (select
            count(*) < #{Naf.schema_name}.queued_jobs.application_run_group_limit
           from
             #{Naf.schema_name}.running_jobs as rj
           where
             rj.application_run_group_name = #{Naf.schema_name}.queued_jobs.application_run_group_name)
        )
      )
      SQL

      return joins(:application_run_group_restriction).
        where(sql)
    end

    def self.runnable_by_machine(machine)
      where("NOT EXISTS (
        SELECT 1
        FROM #{::Naf.schema_name}.historical_job_affinity_tabs AS t
        WHERE t.historical_job_id = #{::Naf.schema_name}.queued_jobs.id AND
          NOT EXISTS (
            SELECT 1
            FROM #{::Naf.schema_name}.machine_affinity_slots AS s
            WHERE s.affinity_id = t.affinity_id AND
              s.machine_id = #{machine.id}
          )
        )"
      )
    end

    def self.prerequisites_finished
      where("NOT EXISTS (
        SELECT 1
        FROM #{::Naf.schema_name}.historical_job_prerequisites AS p
        WHERE p.historical_job_id = #{::Naf.schema_name}.queued_jobs.id AND
          EXISTS (
            SELECT 1
            FROM #{::Naf.schema_name}.historical_jobs AS j
            WHERE p.prerequisite_historical_job_id = j.id AND
              j.finished_at IS NULL
          )
        )"
      )
    end

    def self.weight_available_on_machine(machine)
      machine_parameter_weights = {}
      machine.machine_affinity_slots.each do |slot|
        machine_parameter_weights[slot.affinity_id] = slot.affinity_parameter.to_f
      end

      running_job_weights = ::Naf::RunningJob.affinity_weights(machine)

      queued_jobs = []
      machine_parameter_weights.each do |affinity_id, parameter_weight|
        queued_jobs |= ::Naf::QueuedJob.
          check_weight_sum(affinity_id, running_job_weights[affinity_id], parameter_weight).
          map(&:id)
      end

      if queued_jobs.empty?
        where({})
      else
        where("#{::Naf.schema_name}.queued_jobs.id NOT IN (?)", queued_jobs)
      end
    end

    def self.check_weight_sum(affinity_id, running_job_weight_count, machine_weight_count)
      where("
        id IN (
          SELECT
            historical_job_id
          FROM
            #{::Naf.schema_name}.historical_job_affinity_tabs AS t
          WHERE EXISTS (
            SELECT
              1
            FROM
              #{::Naf.schema_name}.queued_jobs AS j
            WHERE
              t.historical_job_id = j.id
          ) AND EXISTS (
            SELECT
              1
            FROM
              #{::Naf.schema_name}.affinities AS a
            WHERE
              a.id = '#{affinity_id}' AND
                t.affinity_id = a.id
          ) AND COALESCE(affinity_parameter, 0) + #{running_job_weight_count} > #{machine_weight_count}
        )
      ")
    end

  end
end
