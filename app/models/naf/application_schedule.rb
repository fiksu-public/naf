module Naf
  class ApplicationSchedule < NafBase
    include PgAdvisoryLocker

    validates :priority, :numericality => {:only_integer => true}
    validate :visible_enabled_check
    validate :run_interval_at_time_check
    validate :enabled_application_id_unique
    validates  :application_run_group_restriction_id, :presence => true
    validates :application_run_group_name, :presence => true, :length => {:minimum => 3}
    validates :run_interval, :numericality => {:only_integer => true}, :unless => :run_start_minute

    belongs_to :application, :class_name => '::Naf::Application'
    belongs_to :application_run_group_restriction, :class_name => '::Naf::ApplicationRunGroupRestriction'

    has_many :application_schedule_affinity_tabs, :class_name => '::Naf::ApplicationScheduleAffinityTab', :dependent => :destroy
    has_many :affinities, :through => :application_schedule_affinity_tabs

    delegate :title, :to => :application

    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction

    attr_accessible :application_id, :application_run_group_restriction_id, :application_run_group_name,  :run_interval, :priority, :visible, :enabled, :run_start_minute

    SCHEDULES_LOCK_ID = 0

    def to_s
      components = []
      if enabled
        components << "ENABLED"
      else
        if visible
          components << "DISABLED"
        else
          components << "HIDDEN|DISABLED"
        end
      end
      components << "id: #{id}"
      components << "\"#{application.title}\""
      if run_start_minute
        components << "start at: #{"%02d" % (run_start_minute/60)}:#{"%02d" % (run_start_minute%60)}"
      else
        components << "start every: #{run_interval} minutes"
      end

      return "::Naf::ApplicationSchedule<#{components.join(', ')}>"
    end

    # scope like things

    def self.try_lock_schedules
      return try_lock_record(SCHEDULES_LOCK_ID)
    end

    def self.unlock_schedules
      return unlock_record(SCHEDULES_LOCK_ID)
    end

    def self.exact_schedules
      return where('run_start_minute is not null')
    end

    def self.relative_schedules
      return where('run_interval > 0')
    end

    # accessors

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
      errors.add(:application_id, "is enabled and has already been taken") if num_collisions > 0
    end

    def run_interval_at_time_check
      unless run_start_minute.blank?
        if run_interval.present? and (run_interval % (60*24) != 0)
          errors.add(:run_interval, "needs to be nil or a multiple of #{24*60} minutes (one day) since you specified a Run Start Time")
        end
      end
    end
  end
end
