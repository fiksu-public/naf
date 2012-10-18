module Naf
  class AffinityClassification < NafBase

    validates :affinity_classification_name, {:presence => true, :length => {:minimum => 1}}

    has_many :affinities, :dependent => :destroy

    attr_accessible :affinity_classification_name

    def self.purpose
      return @purpose ||= find_by_affinity_classification_name('purpose')
    end

    def self.location
      return @location ||= find_by_affinity_classification_name('location')
    end

    def self.application
      return @application ||= find_by_affinity_classification_name('application')
    end

  end
end
