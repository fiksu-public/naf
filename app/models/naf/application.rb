module Naf
  class Application < NafBase
    
    validates :application_type_id, :command, :title, :presence => true

    validates :title, :uniqueness => true
   
    attr_accessible :title, :command, :application_type_id

    has_one :application_schedule, :class_name => '::Naf::ApplicationSchedule', :dependent => :destroy
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    delegate :script_type_name, :to => :application_type
  end
end
