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

    def self.pre_unpickle(unpickler)
      unpickler.references.merge!(Hash[::Naf::Affinity.all.map do |m|
                                    [{ association_model_name: ::Naf::Affinity.name,
                                       association_classification_value: m.affinity_classification_id,
                                       association_affinity_value: m.affinity_name }, m]
                                  end
                                 ])
    end

    def self.unpickle(preserve, unpickler)
      reference = unpickler.references[{ association_model_name: self.name,
                                         association_classification_value: preserve['affinity_classification_id']['association_value'],
                                         association_affinity_value: preserve['affinity_name'] }]
      if reference.present?
        return {}
      end

      attributes = {}
      reference_methods = []
      preserve.each do |method_name, value|
        unless method_name == 'id'
          if value.is_a?(Hash)
            # this is a reference
            reference_instance = unpickler.retrieve_reference(value)
            if reference_instance.nil?
              logger.error value.inspect
              logger.error { unpickler.references.map{ |r| r.inspect }.join("\n") }
              raise "couldn't find reference for #{value.inspect} in #{preserve.inspect}"
            end
            attributes[method_name.to_sym] = reference_instance.id
          else
            attributes[method_name.to_sym] = value
          end
        end
      end

      instance = self.new
      attributes.each do |method, value|
        instance.send("#{method}=".to_sym, value)
      end
      instance.save!
      logger.info "created #{instance.inspect}"

      return { { association_model_name: self.name,
                 association_classification_value: preserve['affinity_classification_id']['association_value'],
                 association_affinity_value: preserve['affinity_name'] } => instance }
    end

    private

    def check_blank_values
      self.affinity_short_name = nil if self.affinity_short_name.blank?
      self.affinity_note = nil if self.affinity_note.blank?
    end
  end
end
