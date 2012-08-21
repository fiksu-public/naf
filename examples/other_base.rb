module Naf
  class OtherBase < ActiveRecord::Base
    establish_connection "naf_#{Rails.env}"
    self.abstract_class = true
    def self.reset_naf_connection
      self.connection.disconnect!
      self.establish_connection "naf_#{Rails.env}"
    end
  end
end
