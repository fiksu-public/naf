module Naf
  class ApplicationScheduleAffinityTab < NafBase
    belongs_to :application_schedule, :class_name => '::Naf::ApplicationSchedule'
    belongs_to :affinity, :class_name => '::Naf::Affinity'

    delegate :affinity_name, :affinity_classification_name, :to => :affinity

    def script_title
      application_schedule.title
    end

  end
end
