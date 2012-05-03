module Naf
  class NafBase < ActiveRecord::Base
    self.table_name_prefix = 'naf.'
    self.abstract_class = true
  end
end
