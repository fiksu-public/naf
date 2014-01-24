module Naf
  #
  # Things you should know about jobs
  # new jobs older than 1.week will not be searched in the queue.  You should not run programs
  # for more than a 1.week (instead, have them exit and restarted periodically)
  #
  class HistoricalJob < ::Partitioned::ById
    class JobPrerequisiteLoop < StandardError
      def initialize(job)
        super("loop found in prerequisites for #{job}")
      end
    end

    include PgAdvisoryLocker

    # Protect from mass-assignment issue
    attr_accessible :application_id,
                    :application_schedule_id,
                    :application_type_id,
                    :command,
                    :application_run_group_restriction_id,
                    :application_run_group_name,
                    :application_run_group_limit,
                    :priority,
                    :started_on_machine_id,
                    :failed_to_start,
                    :pid,
                    :exit_status,
                    :termination_signal,
                    :state,
                    :request_to_terminate,
                    :marked_dead_by_machine_id,
                    :log_level,
                    :machine_runner_invocation_id

    JOB_STALE_TIME = 1.week
    SYSTEM_TAGS = {
      startup: '$startup',
      pre_work: '$pre-work',
      work: '$work',
      cleanup: '$cleanup'
    }

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :application_schedule,
      class_name: '::Naf::ApplicationSchedule'
    belongs_to :application_type,
      class_name: '::Naf::ApplicationType'
    belongs_to :started_on_machine,
      class_name: '::Naf::Machine',
      foreign_key: 'started_on_machine_id'
    belongs_to :marked_dead_by_machine,
      class_name: '::Naf::Machine',
      foreign_key: 'marked_dead_by_machine_id'
    belongs_to :application,
      class_name: "::Naf::Application"
    belongs_to :application_run_group_restriction,
      class_name: "::Naf::ApplicationRunGroupRestriction"
    belongs_to :machine_runner_invocation,
      class_name: "::Naf::MachineRunnerInvocation"
    has_one :running_job,
      class_name: "::Naf::RunningJob",
      foreign_key: :id
    has_one :queued_job,
      class_name: "::Naf::QueuedJob",
      foreign_key: :id
    # Must access instance methods job_prerequisites through helper methods so we can use partitioning sql
    has_many :historical_job_prerequisites,
      class_name: "::Naf::HistoricalJobPrerequisite",
      dependent: :destroy
    has_many :prerequisites,
      class_name: "::Naf::HistoricalJob",
      through: :historical_job_prerequisites,
      source: :prerequisite_historical_job
    # Access supported through instance methods
    has_many :historical_job_affinity_tabs,
      class_name: "::Naf::HistoricalJobAffinityTab",
      dependent: :destroy
    has_many :affinities,
      class_name: "::Naf::Affinity",
      through: :historical_job_affinity_tabs

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :application_type_id,
              :command,
              :application_run_group_restriction_id, presence: true

    validates :command, length: {
                          minimum: 3
                        }
    validates :application_run_group_limit, numericality: {
                                              only_integer: true,
                                              greater_than_or_equal_to: 1,
                                              less_than: 2147483647,
                                              allow_blank: true
                                            }

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :application_run_group_restriction_name, to: :application_run_group_restriction
    delegate :script_type_name, to: :application_type
    delegate :affinity_name,
             :affinity_classification_name,
             :affinity_short_name, to: :affinity

    #------------------
    # *** Partition ***
    #++++++++++++++++++

    partitioned do |partition|
      partition.foreign_key :application_id, ::Naf::Application.table_name
      partition.foreign_key :application_type_id, ::Naf::ApplicationType.table_name
      partition.foreign_key :application_run_group_restriction_id, ::Naf::ApplicationRunGroupRestriction.table_name
      partition.foreign_key :started_on_machine_id, ::Naf::Machine.table_name
      partition.index :created_at
      partition.index :application_id
      partition.index :started_on_machine_id
      partition.index :command
      partition.index :application_run_group_name
      partition.index :finished_at
      partition.index :exit_status

      partition.janitorial_creates_needed lambda { |model, *partition_key_values|
        sequence_name = model.connection.default_sequence_name(model.table_name)
        current_id = model.find_by_sql("select last_value as id from #{sequence_name}").first.id
        start_range = [0, current_id - (model.partition_table_size * model.partition_num_lead_buffers)].max
        end_range = current_id + (model.partition_table_size * model.partition_num_lead_buffers)
        return model.partition_generate_range(start_range, end_range).reject{|p| model.sql_adapter.partition_exists?(p)}
      }
      partition.janitorial_archives_needed []
      partition.janitorial_drops_needed lambda { |model, *partition_key_values|
        sequence_name = model.connection.default_sequence_name(model.table_name)
        current_id = model.find_by_sql("select last_value as id from #{sequence_name}").first.id
        partition_key_value = current_id - (model.partition_table_size * model.partition_num_lead_buffers)
        partition_key_values_to_drop = []
        while model.sql_adapter.partition_exists?(partition_key_value)
          partition_key_values_to_drop << partition_key_value
          partition_key_value -= model.partition_table_size
        end
        return partition_key_values_to_drop
      }
    end

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.connection
      ::Naf::NafBase.connection
    end

    def self.full_table_name_prefix
      ::Naf::NafBase.full_table_name_prefix
    end

    def self.partition_table_size
      100000
    end

    def self.partition_num_lead_buffers
      10
    end

    def self.queued_between(start_time, end_time)
      where(["created_at >= ? AND created_at <= ?", start_time, end_time])
    end

    def self.canceled
      where(request_to_terminate: true)
    end

    def self.application_last_runs
      where("application_schedule_id IS NOT NULL").
        group("application_schedule_id").
        select("application_schedule_id, MAX(finished_at) AS finished_at").
        reject{ |job| job.finished_at.nil? }
    end

    def self.application_last_queued
      where("application_id IS NOT NULL").
        group("application_id").
        select("application_id, MAX(id) AS id, MAX(created_at) AS created_at")
    end

    def self.finished
      where("finished_at IS NOT NULL OR request_to_terminate = true")
    end

    def self.queued_status
      where("(started_at IS NULL AND request_to_terminate = false) OR
             (finished_at > '#{Time.zone.now - 1.minute}') OR
             (started_at IS NOT NULL AND finished_at IS NULL AND request_to_terminate = false)")
    end

    def self.running_status
      where("(started_at IS NOT NULL AND finished_at IS NULL AND request_to_terminate = false) OR
             (finished_at > '#{Time.zone.now - 1.minute}')")
    end

    def self.queued_with_waiting
      where("(started_at IS NULL AND request_to_terminate = false)")
    end

    def self.errored
      where("finished_at IS NOT NULL AND exit_status > 0 OR request_to_terminate = true")
    end

    def self.lock_for_job_queue(&block)
      lock_record(0, &block)
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def to_s
      components = []

      if started_at.nil?
        components << "QUEUED"
      else
        if finished_at.nil?
          if pid
            extras = []
            extras << pid.to_s
            extras << 'RequestedToTerminate' if request_to_terminate
            components << "RUNNING:#{extras.join(':')}"
          else
            components << "SPAWNING"
          end
        else
          extras = []
          extras << 'RequestedToTerminate' if request_to_terminate
          extras << "FailedToStart" if failed_to_start
          extras << "SIG#{termination_signal}" if termination_signal
          if exit_status && exit_status != 0
            extras << "STATUS=#{exit_status}"
          end
          if extras.length
            extras_str = " (#{extras.join(',')})"
          else
            extras_str = ""
          end
          components << "FINISHED#{extras_str}"
        end
      end
      components << "id: #{id}"
      components << "\"#{command}\""

      return "::Naf::HistoricalJob<#{components.join(', ')}>"
    end

    def title
      application.try(:title)
    end

    def machine_started_on_server_name
      started_on_machine.try(:server_name)
    end

    def machine_started_on_server_address
      started_on_machine.try(:server_address)
    end

    def historical_job_affinity_tabs
      ::Naf::HistoricalJobAffinityTab.
        from_partition(id).
        where(historical_job_id: id)
    end

    def job_affinities
      historical_job_affinity_tabs.map{ |jat| jat.affinity }
    end

    def affinity_ids
      historical_job_affinity_tabs.map{ |jat| jat.affinity_id }
    end

    def historical_job_prerequisites
      ::Naf::HistoricalJobPrerequisite.
        from_partition(id).
        where(historical_job_id: id)
    end

    def prerequisites
      historical_job_prerequisites.
        map{ |hjp| ::Naf::HistoricalJob.from_partition(hjp.prerequisite_historical_job_id).
        find_by_id(hjp.prerequisite_historical_job_id) }.
        reject{ |j| j.nil? }
    end

    # XXX This should go away (it was moved to ConstructionZone::Foreman)

    def verify_prerequisites(these_jobs)
      these_jobs.each do |this_job|
        if this_job.id == id
          raise JobPrerequisiteLoop.new(self)
        else
          verify_prerequisites(this_job.prerequisites)
        end
      end
    end

    def spawn
      application_type.spawn(self)
    end

  end
end
