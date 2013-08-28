module Logical::Naf::ConstructionZone
  class AdHocWorkOrder < WorkOrder
    def initialize(*parameters)
      maybe_hash = parameters.first
      if maybe_hash.is_a?(Hash)
        super(maybe_hash[:command],
              maybe_hash[:application_type] || ::Naf::ApplicationType.rails,
              maybe_hash[:application_run_group_restriction] || ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
              maybe_hash[:application_run_group_name] || :command,
              maybe_hash[:application_run_group_limit] || 1,
              maybe_hash[:priority] || 0,
              maybe_hash[:affinities] || [],
              maybe_hash[:prerequisites] || [],
              maybe_hash[:enqueue_backlogs] || false,
              maybe_hash[:application] || nil,
              maybe_hash[:application_schedule] || nil)
      else
        super(*parameters)
      end
    end
  end
end
