module Naf
  class ApplicationSchedule < NafBase
    include PgAdvisoryLocker

    # Protect from mass-assignment issue
    attr_accessible :application_id,
                    :application_run_group_restriction_id,
                    :application_run_group_name,
                    :run_interval,
                    :priority,
                    :visible,
                    :enabled,
                    :run_start_minute,
                    :application_run_group_limit,
                    :application_schedule_prerequisites_attributes

    SCHEDULES_LOCK_ID = 0

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :application,
      class_name: '::Naf::Application'
    belongs_to :application_run_group_restriction,
      class_name: '::Naf::ApplicationRunGroupRestriction'
    has_many :application_schedule_affinity_tabs,
      class_name: '::Naf::ApplicationScheduleAffinityTab',
      dependent: :destroy
    has_many :affinities,
      through: :application_schedule_affinity_tabs
    has_many :application_schedule_prerequisites,
      class_name: "::Naf::ApplicationSchedulePrerequisite",
      dependent: :destroy
    has_many :prerequisites,
      class_name: "::Naf::ApplicationSchedule",
      through: :application_schedule_prerequisites,
      source: :prerequisite_application_schedule

    accepts_nested_attributes_for :application_schedule_prerequisites, allow_destroy: true

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :priority, numericality: {
                           only_integer: true,
                           greater_than: -2147483648,
                           less_than: 2147483647
                         }
    validates :application_run_group_limit, numericality: {
                                              only_integer: true,
                                              greater_than_or_equal_to: 1,
                                              less_than: 2147483647,
                                              allow_blank: true
                                            }
    validates :run_start_minute, numericality: {
                                   only_integer: true,
                                   greater_than_or_equal_to: 0,
                                   less_than: 24*60,
                                   allow_blank: true }
    validates :run_interval, numericality: {
                               only_integer: true,
                               greater_than_or_equal_to: 0,
                               less_than: 2147483647,
                               allow_blank: true
                             }

    before_save :check_blank_values
    validate :visible_enabled_check
    validate :run_interval_at_time_check
    validate :enabled_application_id_unique
    validate :prerequisite_application_schedule_id_uniqueness
    validates :application_run_group_restriction_id, :presence => true

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :title, to: :application
    delegate :application_run_group_restriction_name, to: :application_run_group_restriction

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

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
      return where('run_interval >= 0')
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

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
      unless (run_start_minute.blank? || run_interval.blank?)
        errors.add(:run_interval, "or Run start minute must be nil")
        errors.add(:run_start_minute, "or Run interval must be nil")
      end
    end

    private

    def prerequisite_application_schedule_id_uniqueness
      if application_schedule_prerequisites.map{ |asp| asp.prerequisite_application_schedule_id }.uniq!
        errors.add(:prerequisite_application_schedule_id, "should be an uniqueness")
      end
    end

    def check_blank_values
      self.application_run_group_name = nil if self.application_run_group_name.blank?
    end

  end
end
