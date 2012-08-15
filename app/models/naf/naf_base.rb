module Naf
  class NafBase < ActiveRecord::Base
    def self.full_table_name_prefix
      "#{JOB_SYSTEM_SCHEMA_NAME}."
    end
    self.abstract_class = true
  end
end
