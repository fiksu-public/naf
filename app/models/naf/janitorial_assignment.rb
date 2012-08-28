module Naf
  class JanitorialAssignment < ::Naf::NafBase
    def self.enabled
      return where("enabled")
    end

    def target_model
      return model_name.constantize rescue nil
    end
  end
end
