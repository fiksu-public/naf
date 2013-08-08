require 'spec_helper'

module Naf
  describe AffinityClassification do
    # Mass-assignment
    [:affinity_classification_name].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should have_many(:affinities) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:affinity_classification_name) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

  end
end
