module Logical::Naf::ConstructionZone
  class Foreman
    def initialize(machine = ::Naf::Machine.current)
      @machine = machine
      @proletariat = Proletariat.new
    end

    def enqueue(work_order)
      if work_order.enqueue_backlogs ||
          !limited_by_run_group?(work_order.application_run_group_restriction,
                                 work_order.application_run_group_name,
                                 work_order.application_run_group_limit)
        @proletariat.create_job(work_order.historical_job_parameters,
                                work_order.historical_job_affinity_tab_parameters,
                                work_order.historical_job_prerequisite_parameters)
      end
    end

    def limited_by_run_group?(application_run_group_restriction, application_run_group_name, application_run_group_limit)
      if (application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.no_limit.id ||
          application_run_group_limit.nil? ||
          application_run_group_name.nil?)
        false
      elsif application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_machine.id
        (::Naf::QueuedJob.where(:application_run_group_name => application_run_group_name).count +
         ::Naf::RunningJob.where(:application_run_group_name => application_run_group_name,
                                 :started_on_machine_id => @machine.id).count) >= application_run_group_limit
      elsif application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines.id
        (::Naf::QueuedJob.where(:application_run_group_name => application_run_group_name).count +
         ::Naf::RunningJob.where(:application_run_group_name => application_run_group_name).count) >= application_run_group_limit
      else
        true
      end
    end
  end
end
