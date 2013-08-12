module Naf
  class Application < NafBase
    # Protect from mass-assignment issue
    attr_accessible :title,
                    :command,
                    :application_type_id,
                    :log_level,
                    :short_name,
                    :deleted,
                    :application_schedule,
                    :application_schedule_attributes

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :application_type,
      class_name: '::Naf::ApplicationType'
    has_one :application_schedule,
      class_name: '::Naf::ApplicationSchedule',
      dependent: :destroy
    has_many :historical_jobs,
      class_name: '::Naf::HistoricalJob'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :application_type_id,
              :command,
              :title, presence: true
    validates :title, uniqueness: true
    validates :short_name, uniqueness: true,
                           allow_blank: true,
                           allow_nil: true,
                           format: {
                             with: /^[a-zA-Z_][a-zA-Z0-9_]*$/,
                             message: "letters should be first"
                           }

    validate :check_references_with_application_schedule_prerequisites
    before_save :check_blank_values
    accepts_nested_attributes_for :application_schedule, allow_destroy: true

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :script_type_name, to: :application_type

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def to_s
      components = []
      components << "DELETED" if deleted
      components << "id: #{id}"
      components << title

      return "::Naf::Application<#{components.join(', ')}>"
    end

    def last_queued_job
      last_queued_job = ::Naf::HistoricalJob.
        queued_between(Time.zone.now - Naf::HistoricalJob::JOB_STALE_TIME, Time.zone.now).
        where(application_id: self.id).
        group(:application_id).
        select("application_id, MAX(id) AS id").first
      last_queued_job ? Naf::HistoricalJob.find(last_queued_job.id) : nil
    end

    def short_name_if_it_exist
      short_name || title
    end

    private

    def check_blank_values
      self.short_name = nil if self.short_name.blank?
      self.log_level = nil if self.log_level.blank?
    end

    def check_references_with_application_schedule_prerequisites
      if application_schedule.try(:marked_for_destruction?)
        prerequisites = Naf::ApplicationSchedulePrerequisite.
          where(prerequisite_application_schedule_id: application_schedule.id).all
        unless prerequisites.blank?
          errors.add(:base, "Cannot delete scheduler, because the following applications are referenced to it: " +
            "#{prerequisites.map{ |pre| pre.application_schedule.title }.join(', ') }")
        end
      end
    end

  end
end
