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
        naf.queued_jobs.application_run_group_name is not null OR
        naf.queued_jobs.application_run_group_limit is not null OR
        naf.application_run_group_restrictions.application_run_group_restriction_name = 'no limit' OR
        (
          naf.application_run_group_restrictions.application_run_group_restriction_name = 'limited per machine' AND
          (select
            count(*) < naf.queued_jobs.application_run_group_limit
           from
             naf.running_jobs as rj
           where
             rj.application_run_group_name = naf.queued_jobs.application_run_group_name and
             rj.started_on_machine_id = #{machine.id})
        ) OR
        (
          application_run_group_restrictions.application_run_group_restriction_name = 'limited per all machines' AND
          (select
            count(*) < naf.queued_jobs.application_run_group_limit
           from
             naf.running_jobs as rj
           where
             rj.application_run_group_name = naf.queued_jobs.application_run_group_name)
        )
      )
      SQL
      return joins(:application_run_group_restriction).
        where(sql)
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

    def self.weight_available_on_machine(machine)
      machine_cpus = machine.parameter_weight('cpus')
      machine_memory = machine.parameter_weight('memory')
      running_job_weights = ::Naf::RunningJob.affinity_weights(machine)

      if machine_cpus > 0 && machine_memory > 0
        ::Naf::QueuedJob.
          check_weight_sum('cpus', running_job_weights[:cpus], machine_cpus).
          check_weight_sum('memory', running_job_weights[:memory], machine_memory)
      elsif machine_cpus > 0 || machine_memory > 0
        parameters = (machine_cpus == 0 ? [machine_memory, 'memory'] : [machine_cpus, 'cpus'])
        ::Naf::QueuedJob.
          check_weight_sum(parameters[1], running_job_weights[parameters[1].to_sym], parameters[0])
      else
        where({})
      end
    end

    def self.check_weight_sum(parameter, running_job_weight_count, machine_weight_count)
      where("
        id IN (
          SELECT
            historical_job_id
          FROM
            naf.historical_job_affinity_tabs AS t
          WHERE EXISTS (
            SELECT
              1
            FROM
              naf.queued_jobs AS j
            WHERE
              t.historical_job_id = j.id
          ) AND EXISTS (
            SELECT
              1
            FROM
              naf.affinities AS a
            WHERE
              a.affinity_name = '#{parameter}' AND
                t.affinity_id = a.id
          ) AND COALESCE(affinity_parameter, 0) + #{running_job_weight_count} <= #{machine_weight_count}
        ) OR NOT EXISTS (
          SELECT
            1
          FROM
            naf.historical_job_affinity_tabs AS t
          WHERE
            t.historical_job_id = queued_jobs.id AND
            EXISTS (
              SELECT
                1
              FROM
                naf.affinities AS a
              WHERE
                a.affinity_name = '#{parameter}' AND
                  t.affinity_id = a.id
            )
        )
      ")
    end

  end
end
