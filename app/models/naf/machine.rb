require 'socket'

module Naf
  class Machine < NafBase
    include ::Af::Application::SafeProxy
    include PgAdvisoryLocker

    IP_REGEX =  /^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$/

    validates :server_address, :presence => true
    validates :server_address, :format => {:with => IP_REGEX, :message => "is not a valid IP address"}, :if => :server_address
    validates :server_address, :uniqueness => true, :if => :correct_server_address?

    has_many :machine_affinity_slots, :class_name => '::Naf::MachineAffinitySlot', :dependent => :destroy
    has_many :affinities, :through => :machine_affinity_slots

    attr_accessible :server_address, :server_name, :server_note, :enabled, :thread_pool_size, :log_level, :marked_down

    def try_lock_for_runner_use(&block)
      return advisory_try_lock(&block)
    end

    def unlock_for_runner_use
      return advisory_unlock
    end

    def machine_logger
      return af_logger(self.class.name)
    end

    def to_s
      components = []
      if enabled
        components << "ENABLED"
      else
        components << "DISABLED"
      end
      if marked_down
        components << "DOWN!"
      end
      components << "id: #{id}"
      components << "address: #{server_address}"
      components << "name: \"#{server_name}\"" unless server_name.blank?
      components << "pool size: #{thread_pool_size}"
      components << "last checked schedules: #{last_checked_schedules_at}"
      components << "last seen: #{last_seen_alive_at}"
      
      return "::Naf::Machine<#{components.join(', ')}>"
    end

    def self.enabled
      return where(:enabled => true)
    end

    def self.up
      return where(:marked_down => false)
    end

    def self.down
      return where(:marked_down => true)
    end

    def self.machine_ip_address
      hostname = nil
      hostname = Socket.gethostname
      return Socket::getaddrinfo(hostname, "echo", Socket::AF_INET)[0][3]
    rescue StandardError => e
      return "127.0.0.1"
    end

    def self.local_machine
      return where(:server_address => machine_ip_address).first
    end

    def correct_server_address?
      server_address.present? and IP_REGEX =~ server_address
    end

    def self.current
      return local_machine
    end

    def self.last_time_schedules_were_checked
      return self.maximum(:last_checked_schedules_at)
    end

    def mark_checked_schedule
      self.last_checked_schedules_at = Time.zone.now
      save!
    end

    def mark_alive
      self.last_seen_alive_at = Time.zone.now
      save!
    end

    def mark_up
      self.marked_down = false
      save!
    end

    def mark_down(by_machine)
      self.marked_down = true
      self.marked_down_by_machine_id = by_machine.id
      self.marked_down_at = Time.zone.now
      save!
    end

    def self.is_it_time_to_check_schedules?(check_period)
      time = Naf::Machine.last_time_schedules_were_checked
      return time.nil? || time < (Time.zone.now - check_period)
    end

    def is_stale?(period)
      return self.last_seen_alive_at.nil? || self.last_seen_alive_at < (Time.zone.now - period)
    end

    def mark_processes_as_dead(by_machine)
      ::Naf::Job.recently_queued.not_finished.started_on(self).each do |job|
        marking_at = Time.zone.now
        machine_logger.alarm "#{by_machine.id} marking #{job} as dead at #{marking_at}"
        job.request_to_terminate = true
        job.marked_dead_by_machine_id = by_machine.id
        job.marked_dead_at = marking_at
        job.finished_at = marking_at
        job.save!
      end
    end

    def mark_machine_down(by_machine)
      marking_at = Time.zone.now
      machine_logger.alarm "#{by_machine.id} marking #{self} as down at #{marking_at}"
      self.marked_down = true
      self.marked_down_by_machine_id = by_machine.id
      self.marked_down_at = marking_at
      save!
      mark_processes_as_dead(by_machine)
    end

    def assigned_jobs
      return ::Naf::Job.fetch_assigned_jobs(self)
    end

    def fetch_next_job
      return ::Naf::Job.fetch_next_job(self)
    end
  end
end
