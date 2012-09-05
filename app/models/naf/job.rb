module Naf

  #
  # Things you should know about jobs
  # new jobs older than 1.week will not be searched in the queue.  You should not run programs
  # for more than a 1.week (instead, have them exit and restarted periodically)
  #

  class Job < ::Partitioned::ById
    include ::Af::Application::SafeProxy
    include ::Af::AdvisoryLocker

    JOB_STALE_TIME = 1.week

    validates :application_type_id, :application_run_group_restriction_id, :presence => true
    validates :application_run_group_name, :command,  {:presence => true, :length => {:minimum => 3}}
    
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    belongs_to :started_on_machine, :class_name => '::Naf::Machine'
    belongs_to :application, :class_name => "::Naf::Application"
    belongs_to :application_run_group_restriction, :class_name => "::Naf::ApplicationRunGroupRestriction"
    has_many :job_affinity_tabs, :class_name => "::Naf::JobAffinityTab", :dependent => :destroy

    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction
    delegate :script_type_name, :to => :application_type

    attr_accessible :application_type_id, :application_id, :application_run_group_restriction_id
    attr_accessible :application_run_group_name, :command, :request_to_terminate, :priority, :log_level

    # partitioning

    def self.connection
      return ::Naf::NafBase.connection
    end

    def self.full_table_name_prefix
      return ::Naf::NafBase.full_table_name_prefix
    end

    def self.partition_table_size
      return 100000
    end

    def self.partition_num_lead_buffers
      return 10
    end

    partitioned do |partition|
      partition.foreign_key :application_id, full_table_name_prefix + "applications"
      partition.foreign_key :application_type_id, full_table_name_prefix + "application_types"
      partition.foreign_key :application_run_group_restriction_id, full_table_name_prefix + "application_run_group_restrictions"
      partition.foreign_key :started_on_machine_id, full_table_name_prefix + "machines"
      partition.index :created_at
      partition.index :application_id
      partition.index :started_on_machine_id
      partition.index :command
      partition.index :application_run_group_name
      partition.index :finished_at
      partition.index :exit_status

      partition.janitorial_creates_needed lambda {|model, *partition_key_values|
        current_id = model.find_by_sql("select last_value as id from #{model.table_name}_id_seq").first.id
        start_range = [0, current_id - (model.partition_table_size * model.partition_num_lead_buffers)].max
        end_range = current_id + (model.partition_table_size * model.partition_num_lead_buffers)
        return model.partition_generate_range(start_range, end_range).reject{|p| model.sql_adapter.partition_exists?(p)}
      }
      partition.janitorial_archives_needed []
      partition.janitorial_drops_needed lambda {|model, *partition_key_values|
        current_id = model.find_by_sql("select last_value as id from #{model.table_name}_id_seq").first.id
        start_range = [0, current_id - (model.partition_table_size * model.partition_num_lead_buffers)].max
        end_range = current_id + (model.partition_table_size * model.partition_num_lead_buffers)
        return model.partition_generate_range(start_range, end_range).reverse.select{|p| model.sql_adapter.partition_exists?(p)}
      }
    end

    # scope like things

    def self.queued_between(start_time, end_time)
      return where(["created_at >= ? AND created_at <= ?", start_time, end_time])
    end

    def self.recently_queued
      return queued_between(Time.zone.now - JOB_STALE_TIME, Time.zone.now)
    end

    def self.canceled
      return where(:request_to_terminate => true)
    end

    def self.application_last_runs
      return recently_queued.
        where("application_id is not null").
        group("application_id").
        select("application_id,max(finished_at) as finished_at").
        reject{|job| job.finished_at.nil? }
    end

    def self.application_last_queued
      return recently_queued.
        where("application_id is not null").
        group("application_id").
        select("application_id,max(id) as id,max(created_at) as created_at")
    end

    def self.not_finished
      return where("finished_at is null")
    end

    def self.started_on(machine)
      return where({:started_on_machine_id => machine.id})
    end

    def self.not_started
      return where({:started_at => nil})
    end

    def self.started
      return where("started_at is not null")
    end

    def self.finished
      return where("finished_at is not null")
    end

    def self.in_run_group(run_group_name)
      return where(:application_run_group_name => run_group_name)
    end

    def self.order_by_priority
      return order("priority,created_at")
    end

    def self.select_affinity_ids
      return select("array(select affinity_id from #{JOB_SYSTEM_SCHEMA_NAME}.job_affinity_tabs where job_id = #{::Naf::Job.partition_table_alias_name}.id order by affinity_id) as affinity_ids")
    end

    def self.possible_jobs
      return recently_queued.not_started
    end

    #

    def title
      return application.try(:title)
    end

    def machine_started_on_server_name
      return started_on_machine.try(:server_name)
    end

    def machine_started_on_server_address
      return started_on_machine.try(:server_address)
    end

    #

    def self.lock_for_job_queue(&block)
      return lock_record(0, &block)
    end

    def self.queue_rails_job(command, priority = 0, affinities = [])
      ::Naf::Job.transaction do
        job = ::Naf::Job.create(:application_type_id => 1,
                                :command => command,
                                :application_run_group_restriction_id => 2,
                                :application_run_group_name => command,
                                :priority => priority)
        ::Naf::JobIdCreatedAt.create(:job_id => job.id, :job_created_at => job.created_at)
        affinities.each do |affinity|
          ::Naf::JobAffinityTab.create(:job_id => job.id, :affinity_id => affinity.id)
        end
      end
    end

    def self.queue_application(application, application_run_group_restriction, application_run_group_name, priority = 0, affinities = [])
      ::Naf::Job.transaction do
        job = ::Naf::Job.create(:application_id => application.id,
                                :application_type_id => application.application_type_id,
                                :command => application.command,
                                :application_run_group_restriction_id => application_run_group_restriction.id,
                                :application_run_group_name => application_run_group_name,
                                :priority => priority)
        ::Naf::JobIdCreatedAt.create(:job_id => job.id, :job_created_at => job.created_at)
        affinities.each do |affinity|
          ::Naf::JobAffinityTab.create(:job_id => job.id, :affinity_id => affinity.id)
        end
      end
    end

    def self.queue_application_schedule(application_schedule)
      queue_application(application_schedule.application,
                        application_schedule.application_run_group_restriction,
                        application_schedule.application_run_group_name,
                        application_schedule.priority,
                        application_schedule.affinities)
    end

    def self.fetch_assigned_jobs(machine)
      return recently_queued.not_finished.started_on(machine)
    end

    def self.fetch_next_job(machine)
      possible_jobs.select("*").select_affinity_ids.order_by_priority.each do |possible_job|
        job_affinity_ids = possible_job.affinity_ids[1..-2].split(',').map(&:to_i)

        # eliminate job if it can't run on this machine
        unless machine.machine_affinity_slots.select(&:required).all? { |slot| job_affinity_ids.include? slot.affinity_id }
          logger.debug "required affinity not found"
          next
        end

        machine_affinity_ids = machine.machine_affinity_slots.map(&:affinity_id)

        # eliminate job if machine can not run this it
        unless job_affinity_ids.all? { |job_affinity_id| machine.affinity_ids.include? job_affinity_id }
          logger.debug "machine does not meet affinity requirements"
          next
        end

        job = nil
        lock_for_job_queue do
          if possible_job.application_run_group_restriction.application_run_group_restriction_name == "one per machine"
            if recently_queued.started.not_finished.started_on(machine).in_run_group(possible_job.application_run_group_name).count > 0
              logger.debug "already running on this machine"
              next
            end
          elsif possible_job.application_run_group_restriction.application_run_group_restriction_name == "one at a time"
            if recently_queued.started.not_finished.in_run_group(possible_job.application_run_group_name).count > 0
              logger.debug "already running"
              next
            end
          else # possible_job.application_run_group_restriction.application_run_group_restriction_name == "no restrictions"
          end

          sql = <<-SQL
             UPDATE #{JOB_SYSTEM_SCHEMA_NAME}.jobs
               SET
                   started_at = NOW(),
                   started_on_machine_id = ?
             WHERE
               id = ? AND
               started_at IS NULL
             RETURNING
               *
          SQL

          job = find_by_sql([sql, machine.id, possible_job.id]).first
        end

        if job.present?
          # found a job
          log_levels = {}
         # log_levels.merge!(machine.log_level) if machine.log_level.present?
         # log_levels.merge!(job.application.log_level) if job.application.try(:log_level).present?
         # job.log_level = log_levels
          return job
        end
      end

      # no jobs found
      return nil
    end

    def spawn
      application_type.spawn(self)
    end

    def self.queue_test
      queue_rails_job("::Naf::Job.test")
    end

    def self.test(*foo)
      seconds = rand 120 + 15
      puts "TEST CALLED: #{Time.zone.now}: #{foo.inspect}: sleeping for #{seconds} seconds"
      sleep(seconds)
      puts "TEST DONE: #{Time.zone.now}: #{foo.inspect}"
    end
  end
end
