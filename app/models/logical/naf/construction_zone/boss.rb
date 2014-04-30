module Logical::Naf::ConstructionZone
  class Boss
    include ::Af::Application::Component
    create_proxy_logger

    def initialize()
      @foreman = Foreman.new()
    end

    def enqueue_application(application,
                            application_run_group_restriction,
                            application_run_group_name,
                            application_run_group_limit = 1,
                            priority = 0,
                            affinities = [],
                            prerequisites = [],
                            enqueue_backlogs = false)
      work_order = ApplicationWorkOrder.new(application,
                                            application_run_group_restriction,
                                            application_run_group_name,
                                            application_run_group_limit,
                                            priority,
                                            affinities,
                                            prerequisites,
                                            enqueue_backlogs)
      @foreman.enqueue(work_order)
    end

    def enqueue_application_schedule(application_schedule, schedules_queued_already = [])
      prerequisite_jobs = []

      # Check if schedule has been queued
      if schedules_queued_already.include? application_schedule.id
        raise ::Naf::HistoricalJob::JobPrerequisiteLoop.new(application_schedule)
      end

      # Keep track of queued schedules
      schedules_queued_already << application_schedule.id
      # Queue application schedule prerequisites
      application_schedule.prerequisites.each do |application_schedule_prerequisite|
        job = enqueue_application_schedule(application_schedule_prerequisite, schedules_queued_already)
        if job.present?
          prerequisite_jobs << job
        else
          return
        end
      end

      # Queue the application
      return enqueue_application(application_schedule.application,
                                 application_schedule.application_run_group_restriction,
                                 application_schedule.application_run_group_name,
                                 application_schedule.application_run_group_limit,
                                 application_schedule.priority,
                                 application_schedule.affinities,
                                 prerequisite_jobs,
                                 application_schedule.enqueue_backlogs)
    end

    def enqueue_rails_command(command,
                              application_run_group_restriction = ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
                              application_run_group_name = :command,
                              application_run_group_limit = 1,
                              priority = 0,
                              affinities = [],
                              prerequisites = [],
                              enqueue_backlogs = false)
      work_order = WorkOrder.new(command,
                                 ::Naf::ApplicationType.rails,
                                 application_run_group_restriction,
                                 application_run_group_name,
                                 application_run_group_limit,
                                 priority,
                                 affinities,
                                 prerequisites,
                                 enqueue_backlogs)
      @foreman.enqueue(work_order)
    end

    def enqueue_command(command,
                        application_type = ::Naf::ApplicationType.rails,
                        application_run_group_restriction = ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
                        application_run_group_name = :command,
                        application_run_group_limit = 1,
                        priority = 0,
                        affinities = [],
                        prerequisites = [],
                        enqueue_backlogs = false)
      work_order = WorkOrder.new(command,
                                 application_type,
                                 application_run_group_restriction,
                                 application_run_group_name,
                                 application_run_group_limit,
                                 priority,
                                 affinities,
                                 prerequisites,
                                 enqueue_backlogs)
      @foreman.enqueue(work_order)
    end

    def enqueue_ad_hoc_command(parameters)
      work_order = AdHocWorkOrder.new(parameters)
      @foreman.enqueue(work_order)
    end

    def enqueue_n_commands_on_machines(parameters, number_of_jobs = :from_limit, machines = [])
      logger.detail "enqueuing #{parameters[:command]} #{number_of_jobs} time(s) on #{machines.length} machine(s)"
      # enqueue the command on each machine
      machines.each do |machine|
        number_of_jobs = (parameters[:application_run_group_quantum] || 1) if number_of_jobs == :from_limit
        logger.info "enqueuing #{parameters[:command]} #{number_of_jobs} time(s) on #{machine}"
        # enqueue the command number_of_jobs times
        (1..number_of_jobs).each do
          machine_parameters = {
            application_run_group_restriction: ::Naf::ApplicationRunGroupRestriction.limited_per_machine
          }.merge(parameters)
          machine_parameters[:affinities] = [machine.affinity] + affinities(machine_parameters)
          work_order = AdHocWorkOrder.new(machine_parameters)

          @foreman.enqueue(work_order)
        end
      end
    end

    def enqueue_n_commands(parameters, number_of_jobs = :from_limit)
      number_of_jobs = (parameters[:application_run_group_quantum] || 1) if number_of_jobs == :from_limit
      logger.info "enqueuing #{parameters[:command]} #{number_of_jobs} time(s)"
      (1..number_of_jobs).each do
        work_order = AdHocWorkOrder.new(parameters)
        @foreman.enqueue(work_order)
      end
    end

    def reenqueue(job)
      enqueue_rails_command(job.command,
                            job.application_run_group_restriction,
                            job.application_run_group_name,
                            job.application_run_group_limit,
                            job.priority,
                            job.historical_job_affinity_tabs.map{|jat| jat.affinity})
    end

    private

    def affinities(params)
      if params[:affinities].nil?
        []
      elsif params[:affinities].is_a? Array
        params[:affinities]
      else
        [params[:affinities]]
      end
    end

  end
end
