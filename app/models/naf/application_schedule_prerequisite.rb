module Naf
  class ApplicationSchedulePrerequisite < ::Naf::NafBase
    # Protect from mass-assignment issue
    attr_accessible :application_schedule_id,
                    :prerequisite_application_schedule_id

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :application_schedule,
      class_name: "::Naf::ApplicationSchedule"
    belongs_to :prerequisite_application_schedule,
      class_name: "::Naf::ApplicationSchedule"

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :prerequisite_application_schedule_id, presence: true
    validates :application_schedule_id, uniqueness: {
                                          scope: :prerequisite_application_schedule_id
                                        }

  end
end
