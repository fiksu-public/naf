module Naf
  class MachineAffinitySlot < NafBase
    belongs_to :machine, :class_name => '::Naf::Machine'
    belongs_to :affinity, :class_name => '::Naf::Affinity'
  end
end
