module Naf
  class MachineAffinitySlot < NafBase
    belongs_to :machine, :class_name => '::Naf::Machine'
    belongs_to :affinity, :class_name => '::Naf::Affinity'

    delegate :affinity_name, :affinity_classification_name, :to => :affinity

    def machine_server_address
      machine.server_address
    end
  end
end
