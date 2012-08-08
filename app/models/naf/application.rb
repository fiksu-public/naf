module Naf
  class Application < NafBase
    has_one :application_schedule, :class_name => '::Naf::ApplicationSchedule'
    has_one :application_type, :class_name => '::Naf::ApplicationType'
  end
end
