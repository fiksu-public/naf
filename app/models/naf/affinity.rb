module Naf
  class Affinity < NafBase
    
    validates :affinity_classification_id, :presence => true
    validates :affinity_name, :presence => true, :length => {:minimum => 1}
    validates :affinity_short_name, :uniqueness => true, :allow_blank => true,
              :format => { :with => /^[a-zA-Z_][a-zA-Z0-9_]*$/,
                           :message => "letters should be first" }
    before_save :check_blank_values

    belongs_to :affinity_classification, :class_name => '::Naf::AffinityClassification'
    has_many :application_schedule_affinity_tabs, :class_name => '::Naf::ApplicationScheduleAffinityTab', :dependent => :destroy
    has_many :machine_affinity_tabs, :class_name => '::Naf::MachineAffinitySlot', :dependent => :destroy


    delegate :affinity_classification_name, :to => :affinity_classification
    
    attr_accessible :affinity_classification_id, :affinity_name, :selectable, :affinity_short_name, :affinity_note

    scope :selectable,  where(:selectable => true)

    def to_s
      components = []
      unless selectable
        components << "UNSELECTABLE"
      end
      components << "classification: \"#{affinity_classification_name}\""
      components << "name: \"#{affinity_name}\""
      
      return "::Naf::Affinity<#{components.join(', ')}>"
    end

    private

    def check_blank_values
      self.affinity_short_name = nil if self.affinity_short_name.blank?
      self.affinity_note = nil if self.affinity_note.blank?
    end
  end
end
