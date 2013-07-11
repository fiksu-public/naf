module Naf
  class RunningJob < NafBase
    # Protect from mass-assignment issue
    attr_accessible :application_id,
                    :application_type_id,
                    :command,
                    :application_run_group_restriction_id,
                    :application_run_group_name,
                    :application_run_group_limit,
                    :started_on_machine_id,
                    :pid,
                    :request_to_terminate,
                    :marked_dead_by_machine_id,
                    :log_level,
                    :started_at

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
    belongs_to :started_on_machine,
      class_name: '::Naf::Machine'
    belongs_to :marked_dead_by_machine,
      class_name: '::Naf::Machine'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :application_type_id,
              :command,
              :application_run_group_restriction_id, presence: true

    #-------------------------
    # *** Class Methods ***
    #+++++++++++++++++++++++++

    def self.started_on(machine)
      return where(started_on_machine_id: machine.id)
    end

    def self.in_run_group(run_group_name)
      return where(application_run_group_name: run_group_name)
    end

    def self.assigned_jobs(machine)
      return started_on(machine)
    end

  end
end
