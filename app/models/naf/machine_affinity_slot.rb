module Naf
  class MachineAffinitySlot < NafBase
    validates :machine_id, :affinity_id, :presence => true

    belongs_to :machine, :class_name => '::Naf::Machine'
    belongs_to :affinity, :class_name => '::Naf::Affinity'

    delegate :affinity_name, :affinity_classification_name, :to => :affinity

    attr_accessible :machine_id, :affinity_id, :required

    def machine_server_address
      machine.server_address
    end

    def machine_server_name
      machine.server_name
    end
  end
end
