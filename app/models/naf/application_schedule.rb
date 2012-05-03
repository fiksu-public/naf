module Naf
  class ApplicationSchedule < NafBase
    include ::Af::AdvisoryLocker

    belongs_to :application, :class_name => '::Naf::Application'
    belongs_to :application_affinty_tab, :class_name => '::Naf::ApplicationAffinityTab'
    belongs_to :application_run_group, :class_name => '::Naf::ApplicationRunGroup'
    belongs_to :application_run_group_restriction, :class_name => '::Naf::ApplicationRunGroupRestriction'
    has_many :application_affinity_tab_pieces, :through => :application_affinty_tab
    has_many :affinities, :through => :application_affinity_tab_pieces

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
