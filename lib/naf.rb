require "naf/engine"
module Naf
  mattr_accessor :controller_class, :model_class, :schema_name
  def self.controller_class
    if @@controller_class
      @@controller_class.constantize
    else
      ActionController::Base
    end
  end
  def self.model_class
    if @@model_class
      @@model_class.constantize
    else
      ActiveRecord::Base
    end
  end

  def self.using_another_database?
    self.model_class != ActiveRecord::Base
  end
end
