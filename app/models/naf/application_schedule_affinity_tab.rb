module Naf
  class ApplicationScheduleAffinityTab < NafBase
    belongs_to :application_schedule, :class_name => '::Naf::ApplicationSchedule'
    belongs_to :affinity, :class_name => '::Naf::Affinity'
  end
end
