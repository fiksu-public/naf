module Logical::Naf::ConstructionZone
  class ApplicationWorkOrder < WorkOrder
    def initialize(application,
                   application_run_group_restriction = ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
                   application_run_group_name = :command,
                   application_run_group_limit = 1,
                   priority = 0,
                   affinities = [],
                   prerequisites = [],
                   enqueue_backlogs = false,
                   application_schedule = nil)
      super(application.command,
            application.application_type,
            application_run_group_restriction,
            application_run_group_name,
            application_run_group_limit,
            priority,
            affinities,
            prerequisites,
            enqueue_backlogs,
            application,
            application_schedule)
    end
  end
end
