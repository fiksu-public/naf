module Logical::Naf::ConstructionZone
  class WorkOrder
    attr_reader :command,
                :application_type,
                :application_run_group_restriction,
                :application_run_group_name,
                :application_run_group_limit,
                :priority,
                :enqueue_backlogs,
                :application,
                :application_schedule

    def initialize(command,
                   application_type = ::Naf::ApplicationType.rails,
                   application_run_group_restriction = ::Naf::ApplicationRunGroupRestriction.limited_per_all_machines,
                   application_run_group_name = :command,
                   application_run_group_limit = 1,
                   priority = 0,
                   affinities = [],
                   prerequisites = [],
                   enqueue_backlogs = false,
                   application = nil,
                   application_schedule = nil)
      @command = command
      @application_type = application_type
      @application_run_group_restriction = application_run_group_restriction
      @application_run_group_name = (application_run_group_name == :command ? command : application_run_group_name)
      @application_run_group_limit = application_run_group_limit
      @priority = priority
      @affinities = if affinities.nil?
                      []
                    elsif affinities.respond_to? :map
                      affinities
                    else
                      [affinities]
                    end
      @prerequisites = prerequisites
      @enqueue_backlogs = enqueue_backlogs
      @application = application
      @application_schedule = application_schedule
    end

    def historical_job_parameters
      {
        command: command,
        application_type_id: application_type.id,
        application_run_group_restriction_id: application_run_group_restriction.id,
        application_run_group_name: application_run_group_name,
        application_run_group_limit: application_run_group_limit,
        priority: priority,
        application_id: application.try(:id),
        application_schedule_id: application_schedule.try(:id)
      }
    end

    def historical_job_affinity_tab_parameters
      @affinities.map do |affinity|
        if affinity.is_a? Symbol
          # short_name of affinity
          affinity_object = {
            affinity_id: ::Naf::Affinity.find_by_affinity_short_name(affinity).try(:id)
          }
          raise "no affinity provided" if affinity_object[:affinity_id].nil?
          affinity_object
        elsif affinity.is_a? ::Naf::Affinity
          {
            affinity_id: affinity.id
          }
        elsif affinity.is_a? ::Naf::Machine
          puts affinity.affinity.inspect
          # affinity_for machine
          {
            affinity_id: affinity.affinity.id
          }
        elsif affinity.is_a? ::Naf::ApplicationScheduleAffinityTab
          # affinity_for application_schedule_affinity_tab
          {
            affinity_id: affinity.affinity_id,
            affinity_parameter: affinity.affinity_parameter
          }
        elsif affinity.is_a? Hash
          # should have key: :affinity_id or :affinity_short_name or :affinity_name
          # may have key: :affinity_parameter
          affinity_object = {}
          if affinity.has_key?(:affinity_id)
            affinity_object[:affinity_id] = affinity[:affinity_id]
          elsif affinity.has_key?(:affinity_name)
            affinity_object[:affinity_id] = ::Naf::Affinity.find_by_affinity_name(affinity[:affinity_name]).try(:id)
          elsif affinity.has_key?(:affinity_short_name)
            affinity_object[:affinity_id] = ::Naf::Affinity.find_by_affinity_short_name(affinity[:affinity_short_name]).try(:id)
          end
          raise "no affinity provided" if affinity_object[:affinity_id].nil?
          affinity_object[:affinity_parameter] = affinity[:affinity_parameter] if affinity.has_key?(:affinity_parameter)
          affinity_object
        else
          raise "unknown affinity kind: #{affinity.inspect}"
        end
      end
    end

    def historical_job_prerequisite_historical_jobs
      # the idea here is that if it is a historical job its prerequisites have
      # already been checked, we only need to check if the prerequisites are NOT
      # the current job we are inserting (which can't happen in the current code path)
      @prerequisites.each do |prerequisite|
        raise "found a non Naf::HistoricalJob in prerequisites: #{prerequisite.inspect}" unless prerequisite.is_a? ::Naf::HistoricalJob
      end
      return @prerequisites
    end
  end
end
