module Naf
  class RunningJob < NafBase
    # Protect from mass-assignment issue
    attr_accessible :application_id,
                    :application_schedule_id,
                    :application_type_id,
                    :command,
                    :application_run_group_restriction_id,
                    :application_run_group_name,
                    :application_run_group_limit,
                    :started_on_machine_id,
                    :pid,
                    :request_to_terminate,
                    :marked_dead_by_machine_id,
                    :log_level,
                    :started_at,
                    :tags

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :historical_job,
      class_name: "::Naf::HistoricalJob",
      foreign_key: :id
    belongs_to :application,
      class_name: "::Naf::Application"
    belongs_to :application_schedule,
      class_name: '::Naf::ApplicationSchedule'
    belongs_to :application_type,
      class_name: '::Naf::ApplicationType'
    belongs_to :application_run_group_restriction,
      class_name: "::Naf::ApplicationRunGroupRestriction"
    belongs_to :started_on_machine,
      class_name: '::Naf::Machine'
    belongs_to :marked_dead_by_machine,
      class_name: '::Naf::Machine'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :application_type_id,
              :command,
              :application_run_group_restriction_id, presence: true

    #-------------------------
    # *** Class Methods ***
    #+++++++++++++++++++++++++

    def self.started_on(machine)
      where(started_on_machine_id: machine.id)
    end

    def self.started_on_invocation(invocation_id)
      joins(:historical_job).
      where("#{::Naf.schema_name}.historical_jobs.machine_runner_invocation_id = #{invocation_id}")
    end

    def self.in_run_group(run_group_name)
      where(application_run_group_name: run_group_name)
    end

    def self.assigned_jobs(machine)
      started_on(machine)
    end

    def self.affinity_weights(machine)
      affinity_ids = ::Naf::Affinity.all.map(&:id)

      job_weights = {}
      affinity_ids.each do |affinity_id|
        job_weights[affinity_id] = 0
      end

      ::Naf::RunningJob.where(started_on_machine_id: machine.id).all.each do |running_job|
        affinity_ids.each do |affinity_id|
          job_weights[affinity_id] += running_job.
            historical_job.historical_job_affinity_tabs.
            where(affinity_id: affinity_id).
            first.try(:affinity_parameter).to_f
        end
      end

      job_weights
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def add_tags(tags_to_add)
      tags_array = nil
      if self.tags.present?
        tags_array = self.tags.gsub(/[{}]/,'').split(',')
        new_tags = '{' + (tags_array | tags_to_add).join(',') + '}'
      else
        new_tags = '{' + tags_to_add.join(',') + '}'
      end

      self.tags = new_tags
      self.save!
    end

    def remove_tags(tags_to_remove)
      if self.tags.present?
        tags_array = self.tags.gsub(/[{}]/,'').split(',')
        new_tags = '{' + (tags_array - tags_to_remove).join(',') + '}'

        self.tags = new_tags
        self.save!
      end
    end

    def remove_all_tags
      self.tags = '{}'
      self.save!
    end


  end
end
