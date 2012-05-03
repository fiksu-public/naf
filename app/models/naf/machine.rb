module Naf
  class Machine < NafBase
    belongs_to :machine_affinity_slot, :class_name => '::Naf::MachineAffinitySlot'

    scope :current, where(:server_address => Socket::getaddrinfo(Socket.gethostname, "echo", Socket::AF_INET)[0][3]).first
    scope :last_time_schedules_were_checked, maximum(:last_checked_schedules_at)
  end
end
