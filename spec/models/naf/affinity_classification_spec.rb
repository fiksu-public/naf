require 'spec_helper'

module Naf
  describe AffinityClassification do
    # Mass-assignment
    [:affinity_classification_name].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to have_many(:affinities) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:affinity_classification_name) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#purpose" do
      let!(:purpose_affinity_classification) { FactoryGirl.create(:purpose_affinity_classification) }

      it "return the purpose affinity classification" do
        expect(::Naf::AffinityClassification.purpose).to eq(purpose_affinity_classification)
      end
    end

    describe "#location" do
      let!(:location_affinity_classification) { FactoryGirl.create(:location_affinity_classification) }

      it "return the location affinity classification" do
        expect(::Naf::AffinityClassification.location).to eq(location_affinity_classification)
      end
    end

    describe "#application" do
      let!(:application_affinity_classification) { FactoryGirl.create(:application_affinity_classification) }

      it "return the application affinity classification" do
        expect(::Naf::AffinityClassification.application).to eq(application_affinity_classification)
      end
    end

    describe "#weight" do
      let!(:weight_affinity_classification) { FactoryGirl.create(:affinity_classification,
                                                                 affinity_classification_name: 'weight',
                                                                 id: 4) }

      it "return the weight affinity classification" do
        expect(::Naf::AffinityClassification.weight).to eq(weight_affinity_classification)
      end
    end

    describe "#machine" do
      it "return the machine affinity classification" do
        machine_affinity_classification = Naf::AffinityClassification.where(:affinity_classification_name => 'machine').first
        if machine_affinity_classification.nil?
          machine_affinity_classification = FactoryGirl.create(:affinity_classification,
                                                               affinity_classification_name: 'machine')
        end
        expect(::Naf::AffinityClassification.machine).to eq(machine_affinity_classification)
      end
    end

  end
end
