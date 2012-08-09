module Naf
  class Affinity < NafBase
    belongs_to :affinity_classification, :class_name => '::Naf::AffinityClassification'

    delegate :affinity_classification_name, :to => :affinity_classification
  end
end
