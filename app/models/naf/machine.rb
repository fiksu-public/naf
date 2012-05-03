require 'socket'

module Naf
  class Machine < NafBase
    has_many :machine_affinity_slot, :class_name => '::Naf::MachineAffinitySlot'
    has_many :affinities, :through => :machine_affinity_slot

    scope :enabled, where(:enabled => true)
    scope :local_machine, where(:server_address => Socket::getaddrinfo(Socket.gethostname, "echo", Socket::AF_INET)[0][3])
    scope :max_last_checked_schedules_at, maximum(:last_checked_schedules_at)

    def self.current
      return local_machine.first
    end

    def self.last_time_schedules_were_checked
      return max_last_checked_schedules_at.first.last_checked_schedules_at
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
  end
end
