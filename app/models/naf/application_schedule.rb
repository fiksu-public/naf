module Naf
  class ApplicationSchedule < NafBase
    include ::Af::AdvisoryLocker

    validates_presence_of :application_run_group_id,  :message => "can't be blank, choose one, or create a new one"
    validates :run_interval, :priority, :numericality => {:only_integer => true}
    validate :visible_enabled_check
    validate :enabled_application_id_unique

    belongs_to :application, :class_name => '::Naf::Application'
    belongs_to :application_run_group, :class_name => '::Naf::ApplicationRunGroup'

    has_many :application_schedule_affinity_tabs, :class_name => '::Naf::ApplicationScheduleAffinityTab', :dependent => :destroy
    has_many :affinities, :through => :application_schedule_affinity_tabs

    delegate :title, :to => :application
    delegate :application_run_group_name, :application_run_group_restriction_name, :to => :application_run_group


    attr_accessible :application_id, :application_run_group_id,  :run_interval, :priority, :visible, :enabled

    SCHEDULES_LOCK_ID = 0

    def self.try_lock_schedules
      return try_lock_record(SCHEDULES_LOCK_ID)
    end

    def self.unlock_schedules
      return unlock_record(SCHEDULES_LOCK_ID)
    end

    def visible_enabled_check
      unless visible or !enabled
        errors.add(:visible, "must be true, or set enabled to false")
        errors.add(:enabled, "must be false, if visible is set to false")
      end
    end

    def enabled_application_id_unique 
      return unless enabled
      if id
        conditions = ["id <> ? AND application_id = ? AND enabled = ?", id, application_id, true]
      else
        conditions = ["application_id = ? AND enabled = ?", application_id, true]
      end
      num_collisions = self.class.count(:conditions => conditions)
      puts "Num Collisions: #{num_collisions}"
      errors.add(:application_id, "is enabled and has already been taken") if num_collisions > 0
    end

    # XXX this should be fixed to figure out of an application schedule is ready to be queued
    scope :should_be_queued, where(:enabled => true)
  end
end
