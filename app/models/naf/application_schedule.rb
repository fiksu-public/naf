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
                    :application_run_group_limit,
                    :application_run_group_quantum,
                    :application_schedule_prerequisites_attributes,
                    :enqueue_backlogs,
                    :run_interval_style_id,
                    :application,
                    :run_interval_style,
                    :application_run_group_restriction

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

    validates :application_run_group_restriction_id,
              :run_interval_style_id,
              :application_id,
              :priority, presence: true
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
    validates :run_interval, numericality: {
                               only_integer: true,
                               greater_than_or_equal_to: 0,
                               less_than: 2147483647,
                               allow_blank: true
                             }

    before_save :check_blank_values
    validate :visible_enabled_check
    validate :prerequisite_application_schedule_id_uniqueness
    validate :run_interval_check

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

    # find the exact based schedules that should be queued
    # select anything that
    #  isn't currently running (or queued) AND
    #  hasn't run since run_interval AND
    #  should have been run by now
    def self.exact_schedules(time, not_finished_applications, application_last_runs)
      custom_current_time = time.to_date + time.strftime('%H').to_i.hours + time.strftime('%M').to_i.minutes
      schedules = ::Naf::ApplicationSchedule.
        joins(:run_interval_style).
        where("#{Naf.schema_name}.run_interval_styles.name IN (?)", ['at beginning of day', 'at beginning of hour']).
        enabled.application_not_deleted.select do |schedule|

        interval_time = time.to_date
        if schedule.run_interval_style.name == 'at beginning of day'
          interval_time += schedule.run_interval.minutes
        elsif schedule.run_interval_style.name == 'at beginning of hour'
          interval_time += time.strftime('%H').to_i.hours + schedule.run_interval.minutes
        end

        (not_finished_applications[schedule.id].nil? &&
          (application_last_runs[schedule.id].nil? ||
            (interval_time >= application_last_runs[schedule.id].finished_at)
          ) &&
          (custom_current_time - interval_time) == 0.seconds
        )
      end

      schedules
    end

    # find the interval based schedules that should be queued
    # select anything that isn't currently running and completed
    # running more than run_interval minutes ago
    def self.relative_schedules(time, not_finished_applications, application_last_runs)
      schedules = ::Naf::ApplicationSchedule.
        joins(:run_interval_style).
        where("#{Naf.schema_name}.run_interval_styles.name = ?", 'after previous run').
        enabled.application_not_deleted.select do |schedule|

        (not_finished_applications[schedule.id].nil? &&
          (application_last_runs[schedule.id].nil? ||
            (time - application_last_runs[schedule.id].finished_at) > schedule.run_interval.minutes
          )
        )
      end

      schedules
    end

    def self.constant_schedules
      ::Naf::ApplicationSchedule.
        joins(:run_interval_style).
        where("#{Naf.schema_name}.run_interval_styles.name = ?", 'keep running').
        enabled.application_not_deleted
    end

    def self.enabled
      where(enabled: true)
    end

    def self.application_not_deleted
      where("
        NOT EXISTS (
          SELECT 1
          FROM #{Naf.schema_name}.applications AS app
          WHERE app.id = #{Naf.schema_name}.application_schedules.application_id AND
            app.deleted = true
        )
      ")
    end

    def self.should_be_queued
      current_time = Time.zone.now
      # Applications that are still running
      not_finished_applications = ::Naf::HistoricalJob.
        queued_between(current_time - Naf::HistoricalJob::JOB_STALE_TIME, current_time).
        where("finished_at IS NULL AND request_to_terminate = false").
        find_all{ |job| job.application_schedule_id.present? }.
        index_by{ |job| job.application_schedule_id }

      # Last ran job for each application
      application_last_runs = ::Naf::HistoricalJob.application_last_runs.
        index_by{ |job| job.application_schedule_id }

      relative_schedules = ::Naf::ApplicationSchedule.
        relative_schedules(current_time, not_finished_applications, application_last_runs)
      exact_schedules = ::Naf::ApplicationSchedule.
        exact_schedules(current_time, not_finished_applications, application_last_runs)
      constant_schedules = ::Naf::ApplicationSchedule.constant_schedules

      foreman = ::Logical::Naf::ConstructionZone::Foreman.new
      return (relative_schedules + exact_schedules + constant_schedules).select do |schedule|
        affinities = []
        schedule.affinities.each do |affinity|
          affinities << { affinity_id: affinity.id }
        end

        schedule.enqueue_backlogs || !foreman.limited_by_run_group?(schedule.application_run_group_restriction,
                                                                    schedule.application_run_group_name,
                                                                    schedule.application_run_group_limit,
                                                                    affinities)
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
      components << ::Logical::Naf::ApplicationSchedule.new(self).display

      return "::Naf::ApplicationSchedule<#{components.join(', ')}>"
    end

    def visible_enabled_check
      unless visible or !enabled
        errors.add(:visible, "must be true, or set enabled to false")
        errors.add(:enabled, "must be false, if visible is set to false")
      end
    end

    # When rolling back from Naf v2.1 to v2.0, check whether run_interval
    # or run_start_minute is nil. Otherwise, just check the presence of
    # run_interval.
    def run_interval_check
      if self.attributes.keys.include?('run_start_minute')
        if !run_start_minute.present? && !run_interval.present?
          errors.add(:run_interval, "or run_start_minute must be nil")
          errors.add(:run_start_minute, "or run_interval must be nil")
        end
      else
        if !run_interval.present?
          errors.add(:run_interval, "must be present")
        end
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
