module Naf
  class Affinity < NafBase
    belongs_to :affinity_classification, :class_name => '::Naf::AffintyClassification'
  end
end
