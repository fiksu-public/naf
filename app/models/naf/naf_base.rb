module Naf
  class NafBase < ::Naf.model_class
    self.abstract_class = true

    def self.full_table_name_prefix
      return "#{::Naf.schema_name}."
    end
  end
end
