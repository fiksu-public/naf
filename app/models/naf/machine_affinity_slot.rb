module Naf
  class MachineAffinitySlot < NafBase
    # Protect from mass-assignment issue
    attr_accessible :machine_id,
                    :affinity_id,
                    :required,
                    :affinity_parameter

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :machine,
      class_name: '::Naf::Machine'
    belongs_to :affinity,
      class_name: '::Naf::Affinity'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :machine_id,
              :affinity_id, presence: true
    validates_uniqueness_of :affinity_id, scope: :machine_id,
                                          message: 'has been taken for this machine'

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :affinity_name,
             :affinity_classification_name,
             :affinity_short_name, to: :affinity

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def machine_server_address
      machine.server_address
    end

    def machine_server_name
      machine.server_name
    end

  end
end
