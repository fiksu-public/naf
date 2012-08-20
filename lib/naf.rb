require "naf/engine"
module Naf
  mattr_accessor :controller_class, :schema_name
  def self.controller_class
    if @@controller_class
      @@controller_class.constantize
    else
      ActionController::Base
    end
  end
end
