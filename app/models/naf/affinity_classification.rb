module Naf
  class AffinityClassification < NafBase
    # Protect from mass-assignment issue
    attr_accessible :affinity_classification_name

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :affinities, dependent: :destroy

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :affinity_classification_name, presence: true,
                                             length: { minimum: 1 }

    #-------------------------
    # *** Class Methods ***
    #+++++++++++++++++++++++++

    def self.purpose
      return @purpose ||= find_by_affinity_classification_name('purpose')
    end

    def self.location
      return @location ||= find_by_affinity_classification_name('location')
    end

    def self.application
      return @application ||= find_by_affinity_classification_name('application')
    end

    def self.weight
      return @weight ||= find_by_affinity_classification_name('weight')
    end

  end
end
