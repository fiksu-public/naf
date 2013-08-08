module Naf
  class ApplicationRunGroupRestriction < NafBase
    # Protect from mass-assignment issue
    attr_accessible :application_run_group_restriction_name

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :application_schedules,
      class_name: '::Naf::ApplicationSchedule'
    has_many :historical_jobs,
      class_name: '::Naf::HistoricalJob'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :application_run_group_restriction_name, presence: true

    #-------------------------
    # *** Class Methods ***
    #+++++++++++++++++++++++++


    def self.no_limit
      return @no_limit ||= find_by_application_run_group_restriction_name('no limit')
    end

    def self.limited_per_machine
      return @limited_per_machine ||= find_by_application_run_group_restriction_name('limited per machine')
    end

    def self.limited_per_all_machines
      return @limited_per_all_machines ||= find_by_application_run_group_restriction_name('limited per all machines')
    end

  end
end
