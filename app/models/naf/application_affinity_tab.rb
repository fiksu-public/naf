module Naf
  class ApplicationAffinityTab < NafBase
    has_many :application_affinity_tab_pieces, :class_name => '::Naf::MachineAffinityTabPiece'
    has_many :affinities, :through => :application_affinity_tab_pieces
  end
end
