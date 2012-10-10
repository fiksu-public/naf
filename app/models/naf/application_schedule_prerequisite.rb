module Naf
  class ApplicationSchedulePrerequisite < ::Naf::NafBase
    belongs_to :application_schedule, :class_name => "::Naf::ApplicationSchedule"
    belongs_to :prerequisite_application_schedule, :class_name => "::Naf::ApplicationSchedule"

    attr_accessible :application_scheule_id, :prerequisite_application_schedule_id
  end
end
