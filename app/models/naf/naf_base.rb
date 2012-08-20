module Naf
  class NafBase < ActiveRecord::Base
    

    self.abstract_class = true

    def self.reset_naf_connection
      self.connection.disconnect!
      self.establish_connection "warehousing_#{Rails.env}"
    end

    def self.full_table_name_prefix
      "#{Naf.schema_name}."
    end
    
    def self.naf_environment
      naf_environments = ActiveRecord::Base.configurations.keys.select{|env| env == "naf_#{Rails.env}"}
      if naf_environments.any?
        return naf_environments.first
      else
        return Rails.env.to_s
      end
    end

    establish_connection NafBase.naf_environment

  end
end
