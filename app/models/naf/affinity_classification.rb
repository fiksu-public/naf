module Naf
  class AffinityClassification < NafBase

    validates :affinity_classification_name, {:presence => true, :length => {:minimum => 3}}

    has_many :affinities, :dependent => :destroy

    attr_accessible :affinity_classification_name

    PURPOSE = 1
    LOCATION = 2
    APPLICATION = 3
  end
end
