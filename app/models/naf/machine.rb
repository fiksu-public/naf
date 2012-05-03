require 'socket'

module Naf
  class Machine < NafBase
    belongs_to :machine_affinity_slot, :class_name => '::Naf::MachineAffinitySlot'

    scope :enabled, where(:enabled => true)
    scope :current, where(:server_address => Socket::getaddrinfo(Socket.gethostname, "echo", Socket::AF_INET)[0][3]).first
    scope :last_time_schedules_were_checked, maximum(:last_checked_schedules_at)

    def mark_checked_schedule
      last_checked_schedules_at = Time.zone.now
      save
    end

    def mark_alive
      last_seen_alive_at = Time.zone.now
      save
    end

    def runner_alive
      # XXX needs to check if runner is alive
      return true
    end

    def self.it_is_time_to_check_schedules?(check_period)
      time = Naf::Machine.last_time_schedules_were_checked
      return time.nil? || time < (Time.zone.now - check_period)
    end

    def is_stale?(period)
      return last_seen_alive_at.nil? || last_seen_alive_at < (Time.zone.now - check_period)
    end

    def mark_processes_as_dead
      # XXX mark processes in queue as dead
    end

    def mark_machine_dead
      enabled = false
      save
      mark_processes_as_dead
    end
  end
end
