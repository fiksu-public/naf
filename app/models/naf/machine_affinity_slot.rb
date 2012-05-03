module Naf
  class MachineAffinitySlot < NafBase
    has_many :machine_affinity_slot_pieces, :class_name => '::Naf::MachineAffinitySlotPiece'
    has_many :affinities, :through => :machine_affinity_slot_pieces
  end
end
