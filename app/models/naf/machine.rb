require 'socket'

module Naf
  class Machine < NafBase
    IP_REGEX =  /^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$/

    validates :server_address, :presence => true
    validates :server_address, :format => {:with => IP_REGEX, :message => "is not a valid IP address"}, :if => :server_address
    validates :server_address, :uniqueness => true, :if => :correct_server_address?

    has_many :machine_affinity_slots, :class_name => '::Naf::MachineAffinitySlot', :dependent => :destroy
    has_many :affinities, :through => :machine_affinity_slots

    attr_accessible :server_address, :server_name, :server_note, :enabled, :thread_pool_size 

    scope :enabled, where(:enabled => true)
    scope :local_machine, where(:server_address => Socket::getaddrinfo(Socket.gethostname, "echo", Socket::AF_INET)[0][3])

    def correct_server_address?
      server_address.present? and IP_REGEX =~ server_address
    end

    def self.current
      return local_machine.first
    end

    def self.last_time_schedules_were_checked
      return self.maximum(:last_checked_schedules_at)
    end

    def mark_checked_schedule
      self.last_checked_schedules_at = Time.zone.now
      save
    end

    def mark_alive
      self.last_seen_alive_at = Time.zone.now
      save
    end

    def runner_alive
      # XXX needs to check if runner is alive
      return true
    end

    def self.is_it_time_to_check_schedules?(check_period)
      time = Naf::Machine.last_time_schedules_were_checked
      return time.nil? || time < (Time.zone.now - check_period)
    end

    def is_stale?(period)
      return self.last_seen_alive_at.nil? || self.last_seen_alive_at < (Time.zone.now - period)
    end

    def mark_processes_as_dead
      # XXX mark processes in queue as dead
    end

    def mark_machine_dead
      self.enabled = false
      save
      mark_processes_as_dead
    end

    def assigned_jobs
      return ::Naf::Job.fetch_assigned_jobs(self)
    end

    def fetch_next_job
      return ::Naf::Job.fetch_next_job(self)
    end
  end
end
