module Naf
  class ApplicationScheduleAffinityTab < NafBase
    validates :application_schedule_id, :affinity_id, :presence => true

    belongs_to :application_schedule, :class_name => '::Naf::ApplicationSchedule'
    belongs_to :affinity, :class_name => '::Naf::Affinity'

    delegate :affinity_name, :affinity_classification_name, :to => :affinity

    attr_accessible :application_schedule_id, :affinity_id

    def script_title
      application_schedule.title
    end

  end
end
