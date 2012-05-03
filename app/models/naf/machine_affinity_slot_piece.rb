module Naf
  class MachineAffinitySlotPiece < NafBase
    belongs_to :machine_affinity_slot, :class_name => '::Naf::MachineAffinitySlot'
    belongs_to :affinity, :class_name => '::Naf::Affinity'
  end
end
