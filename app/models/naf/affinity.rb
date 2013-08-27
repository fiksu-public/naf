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
        affinity_classification.affinity_classification_name == 'location'

        begin
          machine = ::Naf::Machine.find_by_server_address(affinity_name)
        rescue ActiveRecord::StatementInvalid
          return 'Invalid syntax for type inet'
        end

        if machine.blank?
          return "Invalid IP address. There isn't a machine with that address!"
        end
        self.affinity_name = machine.id.to_s

        count = ::Naf::Affinity.
          where(affinity_classification_id: ::Naf::AffinityClassification.
                  find_by_affinity_classification_name('location').id,
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
