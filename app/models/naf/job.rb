module Naf

  #
  # Things you should know about jobs
  # new jobs older than 1.week will not be searched in the queue.  You should not run programs
  # for more than a 1.week (instead, have them exit and restarted periodically)
  #

  class Job < NafBase
    include ::Af::Application::SafeProxy
    include ::Af::AdvisoryLocker

    FILTER_FIELDS = [:application_type_id, :application_run_group_restriction_id, :priority, :failed_to_start, :pid, :exit_status, :request_to_terminate, :started_on_machine_id]
 
    SEARCH_FIELDS = [:command, :application_run_group_name]

    JOB_STALE_TIME = 1.week

    validates  :application_type_id, :application_run_group_restriction_id, :presence => true
    validates :application_run_group_name, :command,  {:presence => true, :length => {:minimum => 3}}
    
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    belongs_to :started_on_machine, :class_name => '::Naf::Machine'
    belongs_to :application, :class_name => "::Naf::Application"
    belongs_to :application_run_group_restriction, :class_name => "::Naf::ApplicationRunGroupRestriction"
    has_many :job_affinity_tabs, :class_name => "::Naf::JobAffinityTab", :dependent => :destroy

    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction
    delegate :script_type_name, :to => :application_type

    attr_accessible :application_type_id, :application_id, :application_run_group_restriction_id, :application_run_group_name, :command, :request_to_terminate
    attr_accessible :priority
    # scope like things

    def self.queued_between(start_time, end_time)
      return where(["created_at >= ? AND created_at <= ?", start_time, end_time])
    end

    def self.recently_queued
      return queued_between(Time.zone.now - JOB_STALE_TIME, Time.zone.now)
    end

    def self.not_finished
      return where({:finished_at => nil})
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

    def self.in_run_group(run_group_name)
      return where(:application_run_group_name => run_group_name)
    end

    def self.order_by_priority
      return order("priority,created_at")
    end

    def self.select_affinity_ids
      return select("array(select affinity_id from #{JOB_SYSTEM_SCHEMA_NAME}.job_affinity_tabs where job_id = jobs.id order by affinity_id) as affinity_ids")
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

    def self.queue_rails_job(command, affinities = [], priority = 0)
      create(:application_type_id => 1,
             :command => command,
             :application_run_group_restriction_id => 2,
             :application_run_group_name => command,
             :priority => priority)
    end

    def self.fetch_assigned_jobs(machine)
      return recently_queued.not_finished.started_on(machine)
    end

    def self.fetch_next_job(machine)
      possible_jobs.select("*").select_affinity_ids.order_by_priority.each do |possible_job|
        job_affinity_ids = possible_job.affinity_ids[1..-2].split(',').map(&:to_i)

        # eliminate job if it can't run on this machine
        unless machine.machine_affinity_slots.select(&:required).all? { |slot| job_affinity_ids.include? slot.affinity_id }
          #logger.debug "required affinity not found"
          next
        end

        machine_affinity_ids = machine.machine_affinity_slots.map(&:affinity_id)

        # eliminate job if machine can not run this it
        unless job_affinity_ids.all? { |job_affinity_id| machine.affinity_ids.include? job_affinity_id }
          #logger.debug "machine does not meet affinity requirements"
          next
        end

        job = nil
        lock_for_job_queue do
          if possible_job.application_run_group_restriction.application_run_group_restriction_name == "one per machine"
            if recently_queued.started.not_finished.started_on(machine).in_run_group(possible_job.application_run_group_name).count > 0
              #logger.debug "already running on this machine"
              next
            end
          elsif possible_job.application_run_group_restriction.application_run_group_restriction_name == "one at a time"
            if recently_queued.started.not_finished.in_run_group(possible_job.application_run_group_name).count > 0
              #logger.debug "already running"
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
          return job
        end
      end

      # no jobs found
      return nil
    end

    def execute
      application_type.execute(self)
    end

    def self.test(*foo)
      puts "TEST CALLED: #{Time.zone.now}: #{foo.inspect}"
    end

    # Given search, a hash of the search query for jobs on the queue,
    # build up and return the ActiveRecord scope
    #
    # We eventually build up these results over created_at/1.week partitions.
    def self.search(search)
      order, direction = search[:order], search[:direction]
      job_scope = order("#{order} #{direction}").limit(search[:limit]).offset(search[:offset].to_i*search[:limit].to_i)
      if search[:running].present?
        machine_id_value = search[:running] == "true" ? "not null" : "null"
        job_scope = job_scope.where("started_on_machine_id is #{machine_id_value}")
      end
      FILTER_FIELDS.each do |field|
        job_scope = job_scope.where(field => search[field]) if search[field].present?
      end
      SEARCH_FIELDS.each do |field|
        job_scope = job_scope.where(["lower(#{field}) ~ ?", search[field].downcase]) if search[field].present?
      end
      job_scope
    end

    # Format the hash of a job record nicely for the table
    def serializable_hash_for_table_view
      more_attributes = [:title, :script_type_name, :application_run_group_restriction_name, 
                         :machine_started_on_server_name, :machine_started_on_server_address]
      job_hash = as_json(:methods => more_attributes)
      job_hash.each do |key, value| 
        if value.kind_of?(Time)
          job_hash[key] = value.strftime("%Y-%m-%d %H:%M:%S") 
        end
      end
    end
  end
end
