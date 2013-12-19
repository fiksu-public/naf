module Logical::Naf::ConstructionZone
  class Foreman
    include ::Af::Application::Component
    create_proxy_logger

    def initialize()
      @proletariat = Proletariat.new
    end

    def enqueue(work_order)
      unless work_order.enqueue_backlogs
        if limited_by_run_group?(work_order.application_run_group_restriction,
                                 work_order.application_run_group_name,
                                 work_order.application_run_group_limit)
          logger.warn "work order limited by run queue limits #{work_order.inspect}"
          return nil
        end
      end
      @proletariat.create_job(work_order.historical_job_parameters,
                              work_order.historical_job_affinity_tab_parameters,
                              work_order.historical_job_prerequisite_historical_jobs)
    end

    def limited_by_run_group?(application_run_group_restriction, application_run_group_name, application_run_group_limit)
      if (application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.no_limit.id ||
          application_run_group_limit.nil? ||
          application_run_group_name.nil?)
        false
      elsif application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_machine.id
        # XXX this is difficult to figure out, so we punt for now
        # XXX we should check if there is any machine affinity (must pass that in) and
        # XXX if so check if that machine has this application group running on it.
        # XXX but this code is only used as a heuristic for queues

        #(::Naf::QueuedJob.where(:application_run_group_name => application_run_group_name).count +
        #::Naf::RunningJob.where(:application_run_group_name => application_run_group_name,
        #:started_on_machine_id => @machine.id).count) >= application_run_group_limit

        # XXX just returning false
        false
      elsif application_run_group_restriction.id == ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines.id
        (::Naf::QueuedJob.where(:application_run_group_name => application_run_group_name).count +
         ::Naf::RunningJob.where(:application_run_group_name => application_run_group_name).count) >= application_run_group_limit
      else
        logger.warn "not limited by run group restriction but don't know why: #{application_run_group_restriction.inspect}"
        true
      end
    end
  end
end
