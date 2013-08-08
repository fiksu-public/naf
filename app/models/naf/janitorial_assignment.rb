module Naf
  class JanitorialAssignment < ::Naf::NafBase

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.enabled
      return where("enabled")
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def target_model
      return model_name.constantize rescue nil
    end

  end
end
