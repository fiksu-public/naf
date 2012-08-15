module Naf
  class Job < NafBase
    include ::Af::Application::SafeProxy

    validates  :application_id, :application_run_group_restriction_id, :presence => true
    validates :application_run_group_name, {:presence => true, :length => {:minimum => 3}}
    
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    belongs_to :started_on_machine, :class_name => '::Naf::Machine'
    belongs_to :application, :class_name => "::Naf::Application"
    belongs_to :application_run_group_restriction, :class_name => "::Naf::ApplicationRunGroupRestriction"
    has_many :job_affinity_tabs, :class_name => "::Naf::JobAffinityTab", :dependent => :destroy

    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction
    delegate :command, :script_type_name, :title, :to => :application

    attr_accessible :application_id, :application_run_group_restriction_id, :application_run_group_name

    def machine_started_on_server_name
      return started_on_machine.try(:server_name)
    end

    def machine_started_on_server_address
      return started_on_machine.try(:server_address)
    end

    def self.fetch_next_job(machine)
      select("jobs.*").
        select("(select array(affinity_id) from #{JOB_SYSTEM_SCHEMA_NAME}.job_affinity_tabs where job_id = jobs.id order by affinity_id) as affinity_ids").
        where(["jobs.created_at >= ? AND jobs.created_at <= ? AND jobs.started_at IS NULL", Time.zone.now - 1.week, Time.zone.now]).
        order("jobs.priority,jobs.created_at").each do |possible_job|

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
            if where(["created_at >= ? AND created_at <= ? AND started_at IS NULL", Time.zone.now - 1.week, Time.zone.now]).
                where("started_at is not null").
                where("finished_at is null").
                where(:application_run_group_name => possible_job.application_run_group_name).
                where(:started_on_machine_id => machine.id).count > 0
              #logger.debug "already running on this machine"
              next
            end
          elsif possible_job.run_group_restriction.name == "one at a time"
            if where(["created_at >= ? AND created_at <= ? AND started_at IS NULL", Time.zone.now - 1.week, Time.zone.now]).
                where("started_at is not null").
                where("finished_at is null").
                where(:application_run_group_name => possible_job.application_run_group_name).count > 0
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
