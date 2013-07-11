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
      return order("priority, created_at")
    end

  end
end
