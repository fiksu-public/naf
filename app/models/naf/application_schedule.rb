module Naf
  class ApplicationSchedule < NafBase
    include ::Af::AdvisoryLocker

    validates :application_id, :application_run_group_restriction_id, :run_interval, :presence => true
    validates_presence_of :application_run_group_id,  :message => "can't be blank, choose one, or create a new one"
    validates :run_interval, :priority, :numericality => {:only_integer => true}


    belongs_to :application, :class_name => '::Naf::Application'
    belongs_to :application_run_group, :class_name => '::Naf::ApplicationRunGroup'
    belongs_to :application_run_group_restriction, :class_name => '::Naf::ApplicationRunGroupRestriction'
    has_many :application_schedule_affinity_tabs, :class_name => '::Naf::ApplicationScheduleAffinityTab', :dependent => :destroy
    has_many :affinities, :through => :application_schedule_affinity_tabs

    delegate :title, :to => :application
    delegate :application_run_group_name, :to => :application_run_group
    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction

    attr_accessible :application_id, :application_run_group_id, :application_run_group_restriction_id, :run_interval, :priority, :visible, :enabled

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
