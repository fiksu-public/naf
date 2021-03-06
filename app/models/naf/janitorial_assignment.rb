module Naf
  class JanitorialAssignment < ::Naf::NafBase

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.enabled
      return where("enabled")
    end

    def self.pickleables(pickler)
      old_model_names = ['::Naf::Job',
                         '::Naf::JobCreatedAt',
                         '::Naf::JobPrerequisite',
                         '::Naf::JobAffinityTab']
      return where('model_name NOT IN (?)', old_model_names)
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def target_model
      return model_name.constantize rescue nil
    end

    def self.pickleables(pickler)
      old_model_names = ['::Naf::Job',
                         '::Naf::JobCreatedAt',
                         '::Naf::JobPrerequisite',
                         '::Naf::JobAffinityTab']
      return where('model_name NOT IN (?)', old_model_names)
    end

  end
end
