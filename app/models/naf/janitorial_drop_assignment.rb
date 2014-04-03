module Naf
  class JanitorialDropAssignment < JanitorialAssignment
    # Protect from mass-assignment issue
    attr_accessible :model_name,
                    :assignment_order,
                    :enabled,
                    :deleted

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validate :deleted_enabled_check
    validates :assignment_order, numericality: {
                                   only_integer: true,
                                   greater_than_or_equal_to: 0,
                                   less_than: 2147483647
                                 }
    validates :model_name, presence: true

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def do_janitorial_work(target_model)
      target_model.drop_old_partitions
    end

    def deleted_enabled_check
      if deleted && enabled
        errors.add(:deleted, "or Enabled must be false")
      end
    end

  end
end
