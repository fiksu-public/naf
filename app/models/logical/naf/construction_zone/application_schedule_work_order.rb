module Logical::Naf::ConstructionZone
  class ApplicationScheduleWorkOrder < ApplicationWorkOrder
    def initialize(application_schedule)
      super(application_schedule.application,
            application_schedule.application_run_group_restriction,
            application_schedule.application_run_group_name,
            application_schedule.application_run_group_limit,
            application_schedule.priority,
            application_schedule.affinities,
            application_schedule.prerequisites,
            application_schedule.enqueue_backlogs,
            application_schedule)
    end
  end
end
