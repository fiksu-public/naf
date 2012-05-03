module Naf
  class ApplicationSchedule < NafBase
    include ::Af::AdvisoryLocker

    belongs_to :application, :class_name => '::Naf::Application'
    belongs_to :application_run_group, :class_name => '::Naf::ApplicationRunGroup'
    belongs_to :application_run_group_restriction, :class_name => '::Naf::ApplicationRunGroupRestriction'
    has_many :application_schedule_affinity_tabs, :class_name => '::Naf::ApplicationScheduleAffinityTab'
    has_many :affinities, :through => :application_schedule_affinity_tabs

    SCHEDULES_LOCK_ID = 0

    def self.try_lock_schedules
      return try_lock_record(SCHEDULES_LOCK_ID)
    end

    def self.unlock_schedules
      return unlock_record(SCHEDULES_LOCK_ID)
    end

    # XXX this should be fixed to figure out of an application schedule is ready to be queued
    scope :should_be_queued, where(:enabled => true)
  end
end
