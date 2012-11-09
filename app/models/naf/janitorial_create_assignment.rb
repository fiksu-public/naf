module Naf
  class JanitorialCreateAssignment < JanitorialAssignment
    validate :deleted_enabled_check
    validates :assignment_order,
          :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :less_than => 2147483647 }
    validates :model_name, :presence => true

    attr_accessible :model_name, :assignment_order, :enabled, :deleted

    def do_janitorial_work(target_model)
      target_model.create_new_partitions
    end

    def deleted_enabled_check
      if deleted && enabled
        errors.add(:deleted, "or Enabled must be false")
      end
    end
  end
end
