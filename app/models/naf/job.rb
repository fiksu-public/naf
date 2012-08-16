module Naf

  #
  # Things you should know about jobs
  # new jobs older than 1.week will not be searched in the queue.  You should not run programs
  # for more than a 1.week (instead, have them exit and restarted periodically)
  #

  class Job < NafBase
    include ::Af::Application::SafeProxy

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

    # scope like things

    def self.queued_between(start_time, end_time)
      return where(["created_at >= ? AND created_at <= ?", start_time, end_time)]).
    end

    def self.recently_queued
      return created_at_between(Time.zone.now - JOB_STALE_TIME, Time.zone.now)
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
      return select("(select array(affinity_id) from #{JOB_SYSTEM_SCHEMA_NAME}.job_affinity_tabs where job_id = jobs.id order by affinity_id) as affinity_ids")
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

    def self.fetch_assigned_jobs(machine)
      return recently_queued.not_finished.started_on(machine)
    end

    def self.fetch_next_job(machine)
      select("*").select_affinity_ids.recently_queued.not_started.order_by_priority.each do |possible_job|
        job_affinity_ids = possible_jobs.affinity_ids[1..-2].split(',').map(&:to_i)

        # eliminate job if it can't run on this machine
        unless machine.machine_affinty_slots.select(&:required).all? { |slot| job_affinity_ids.include? slot.affinity_id }
          #logger.debug "required affinity not found"
          next
        end

        machine_affinity_ids = machine.machine_affinty_slots.map(&:affinity_id)

        # eliminate job if machine can not run this it
        unless job_affinity_ids.all? { |job_affinity_id| machine.affinity_ids.include? job_affinity_id }
          #logger.debug "machine does not meet affinity requirements"
          next
        end

        job = nil
        lock_for_job_queue do
          if possible_job.run_group_restriction.name == "one per machine"
            if recently_queued.started.not_finished.started_on(machine).in_run_group(possible_job.application_run_group_name).count > 0
              #logger.debug "already running on this machine"
              next
            end
          elsif possible_job.run_group_restriction.name == "one at a time"
            if recently_queued.started.not_finished.in_run_group(possible_job.application_run_group_name).count > 0
              #logger.debug "already running"
              next
            end
          else # possible_job.run_group_restriction.name == "no restrictions"
          end

          sql = <<-SQL
             UPDATE jobs
               SET
                   started_at = NOW(),
                   started_on_machine_id = ?,
             WHERE
               id = ? AND
               started_at IS NULL
             RETURNING
               *
          SQL

          job = find_by_sql([sql, machine.id, possible_job.id]).first
        end

        return job if job.present?
      end
        
    end
  end
end
