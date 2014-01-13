module Naf
  class RunIntervalStyle < NafBase
    # Protect from mass-assignment issue
    attr_accessible :name

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :application_schedules,
      class_name: '::Naf::ApplicationSchedule'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :name, presence: true

  end
end
