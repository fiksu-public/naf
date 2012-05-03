module Naf
  class ApplicationAffinityTabPiece < NafBase
    belongs_to :application_affinity_tab, :class_name => '::Naf::ApplicationAffinityTab'
    belongs_to :affinity, :class_name => '::Naf::Affinity'
  end
end
