module Logical::Naf::ConstructionZone
  class Boss
    def initialize(machine = Naf::Machine.current)
      @foreman = Foreman.new(machine)
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
                                            application_run_group_limit = 1,
                                            priority = 0,
                                            affinities = [],
                                            prerequisites = [],
                                            enqueue_backlogs = false)
      @foreman.enqueue(work_order)
    end

    def enqueue_application_schedule(application_schedule)
      work_order = ApplicationScheduleWorkOrder.new(application_schedule)
      @foreman.enqueue(work_order)
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
      work_order = WorkOrder.new(application_type,
                                 command,
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
      machines.each do |machine|
        number_of_jobs = (parameters[:application_run_group_limit] || 1) if number_of_jobs == :from_limit
        (1..number_of_jobs).each do
          machine_parameters = {
            :application_run_group_limit => number_of_jobs,
            :application_run_group_restriction => :Naf::ApplicationRunGroupRestriction.limited_per_machine
          }.merge(parameters)
          machine_parameters[:affinities] = (machine_parameters[:affinities] || []) + [machine.affinity]
          work_order = AdHocWorkOrder.new(machine_parameters)
          @foreman.enqueue(work_order)
        end
      end
    end

    def enqueue_n_commands(parameters, number_of_jobs = :from_limit)
      number_of_jobs = (parameters[:application_run_group_limit] || 1) if number_of_jobs == :from_limit
      (1..number_of_jobs).each do
        work_order = AdHocWorkOrder.new({:application_run_group_limit => number_of_jobs}.merge(parameters))
        @foreman.enqueue(work_order)
      end
    end

    def reenqueue(job)
      enqueue_rails_command(job.command,
                            job.application_run_group_restriction,
                            job.application_run_group_name,
                            job.application_run_group_limit,
                            job.priority,
                            job.job_affinity_tabs.map{|jat| jat.affinity})
    end

  end
end
