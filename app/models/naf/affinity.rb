module Naf
  class Affinity < NafBase
    # Protect from mass-assignment issue
    attr_accessible :affinity_classification_id,
                    :affinity_name,
                    :selectable,
                    :affinity_short_name,
                    :affinity_note

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :affinity_classification,
      class_name: '::Naf::AffinityClassification'
    has_many :application_schedule_affinity_tabs,
      class_name: '::Naf::ApplicationScheduleAffinityTab',
      dependent: :destroy
    has_many :machine_affinity_slots,
      class_name: '::Naf::MachineAffinitySlot',
      dependent: :destroy

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :affinity_classification_id,
              :affinity_name, presence: true
    validates :affinity_name, length: { minimum: 1 }
    validates :affinity_short_name, uniqueness: true,
                                    allow_blank: true,
                                    allow_nil: true,
                                    format: {
                                      with: /^[a-zA-Z_][a-zA-Z0-9_]*$/,
                                      message: 'letters should be first'
                                    }

    before_save :check_blank_values

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :affinity_classification_name, to: :affinity_classification

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.selectable
      where(selectable: true)
    end

    def self.names_list
      selectable.map do |a|
        classification = a.affinity_classification
        if classification.affinity_classification_name == 'machine'
          if a.affinity_short_name.present?
            [a.affinity_short_name, a.id]
          elsif ::Naf::Machine.find_by_id(Integer(a.affinity_name)).present?
            machine = ::Naf::Machine.find_by_id(Integer(a.affinity_name))
            [machine.hostname, a.id]
          else
            ['Bad affinity: ' + classification.affinity_classification_name + ', ' + a.affinity_name, a.id]
          end
        else
          [classification.affinity_classification_name + ', ' + a.affinity_name, a.id]
        end
      end
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

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def to_s
      components = []
      components << "UNSELECTABLE" unless selectable
      components << "classification: \"#{affinity_classification_name}\""
      components << "name: \"#{affinity_name}\""

      return "::Naf::Affinity<#{components.join(', ')}>"
    end

    def validate_affinity_name
      if affinity_classification.present? &&
        affinity_classification.affinity_classification_name == 'machine'

        machine = ::Naf::Machine.find_by_id(affinity_name)
        if machine.blank?
          return "There isn't a machine with that id!"
        end

        count = ::Naf::Affinity.
          where(affinity_classification_id: ::Naf::AffinityClassification.
                  find_by_affinity_classification_name('machine').id,
                affinity_name: machine.id.to_s).count

        if count > 0
          return 'An affinity with the pair value (affinity_classification_id, affinity_name) already exists!'
        end
      end

      nil
    end

    private

    def check_blank_values
      self.affinity_short_name = nil if self.affinity_short_name.blank?
      self.affinity_note = nil if self.affinity_note.blank?
    end

  end
end
