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
                    :application_schedule_prerequisites_attributes,
                    :enqueue_backlogs,
                    :run_interval_style_id

    SCHEDULES_LOCK_ID = 0

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :application,
      class_name: '::Naf::Application'
    belongs_to :application_run_group_restriction,
      class_name: '::Naf::ApplicationRunGroupRestriction'
    belongs_to :run_interval_style,
      class_name: '::Naf::RunIntervalStyle'
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

    validates :application_run_group_restriction_id, presence: true
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
                                   allow_blank: true
                                 }
    validates :run_interval, numericality: {
                               only_integer: true,
                               greater_than_or_equal_to: 0,
                               less_than: 2147483647,
                               allow_blank: true
                             }

    before_save :check_blank_values
    validate :visible_enabled_check
    validate :enabled_application_id_unique
    validate :prerequisite_application_schedule_id_uniqueness

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :title, to: :application
    delegate :application_run_group_restriction_name, to: :application_run_group_restriction

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.try_lock_schedules
      try_lock_record(SCHEDULES_LOCK_ID)
    end

    def self.unlock_schedules
      unlock_record(SCHEDULES_LOCK_ID)
    end

    # find the run_start_minute based schedules
    # select anything that
    #  isn't currently running (or queued) AND
    #  hasn't run since run_interval AND
    #  should have been run by now
    def self.exact_schedules(time, not_finished_applications, application_last_runs)
      custom_current_time = time.to_date + time.strftime('%H').to_i.hours + time.strftime('%M').to_i.minutes
      schedules = ::Naf::ApplicationSchedule.
        joins(:run_interval_style).
        where("#{Naf.schema_name}.run_interval_styles.name IN (?)", ['at beginning of hour', 'after previous run']).
        enabled.select do |schedule|

        interval_time = time.to_date
        if schedule.run_interval_style.name == 'at beginning of day'
          interval_time += schedule.run_interval.minutes
        elsif schedule.run_interval_style.name == 'at beginning of hour'
          interval_time += time.strftime('%H').to_i.hours + schedule.run_interval.minutes
        end

        (not_finished_applications[schedule.application_id].nil? &&
          (application_last_runs[schedule.application_id].nil? ||
            (interval_time >= application_last_runs[schedule.application_id].finished_at)
          ) &&
          (custom_current_time - interval_time) == 0.seconds
        )
      end

      schedules
    end

    # find the run_interval based schedules that should be queued
    # select anything that isn't currently running and completed
    # running more than run_interval minutes ago
    def self.relative_schedules(time, not_finished_applications, application_last_runs)
      schedules = ::Naf::ApplicationSchedule.
        joins(:run_interval_style).
        where("#{Naf.schema_name}.run_interval_styles.name = ?", 'after previous run').
        enabled.select do |schedule|

        (not_finished_applications[schedule.application_id].nil? &&
          (application_last_runs[schedule.application_id].nil? ||
            (time - application_last_runs[schedule.application_id].finished_at) > schedule.run_interval.minutes
          )
        )
      end

      schedules
    end

    def self.constant_schedules
      ::Naf::ApplicationSchedule.
        joins(:run_interval_style).
        where("#{Naf.schema_name}.run_interval_styles.name = ?", 'keep running').
        enabled
    end

    def self.enabled
      where(enabled: true)
    end

    def self.should_be_queued
      current_time = Time.zone.now
      # Applications that are still running
      not_finished_applications = ::Naf::HistoricalJob.
        queued_between(current_time - Naf::HistoricalJob::JOB_STALE_TIME, current_time).
        where("finished_at IS NULL AND request_to_terminate = false").
        find_all{ |job| job.application_id.present? }.
        index_by{ |job| job.application_id }

      # Last ran job for each application
      application_last_runs = ::Naf::HistoricalJob.application_last_runs.
        index_by{ |job| job.application_id }

      relative_schedules = ::Naf::ApplicationSchedule.
        relative_schedules(current_time, not_finished_applications, application_last_runs)
      exact_schedules = ::Naf::ApplicationSchedule.
        exact_schedules(current_time, not_finished_applications, application_last_runs)
      constant_schedules = ::Naf::ApplicationSchedule.constant_schedules

      foreman = ::Logical::Naf::ConstructionZone::Foreman.new
      return (relative_schedules + exact_schedules + constant_schedules).select do |schedule|
        schedule.enqueue_backlogs || !foreman.limited_by_run_group?(schedule.application_run_group_restriction,
                                                                    schedule.application_run_group_name,
                                                                    schedule.application_run_group_limit)
      end
    end

    def self.pickleables
      # check the application is deleted
      self.where(deleted: false)
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

      num_collisions = self.class.count(conditions: conditions)
      errors.add(:application_id, "is enabled and has already been taken") if num_collisions > 0
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
