require 'socket'

module Naf
  class Machine < NafBase
    include ::Af::Application::SafeProxy
    include PgAdvisoryLocker

    # Protect from mass-assignment issue
    attr_accessible :server_address,
                    :server_name,
                    :server_note,
                    :enabled,
                    :thread_pool_size,
                    :log_level,
                    :marked_down,
                    :short_name

    IP_REGEX =  /^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$/

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :server_address, :presence => true
    validates :short_name, uniqueness: true,
                           allow_blank: true,
                           format: {
                             with: /^[a-zA-Z_][a-zA-Z0-9_]*$/,
                             message: "letters should be first (use only letters and numbers)"
                           }
    validates :server_address, format: {
                                 with: IP_REGEX,
                                 message: "is not a valid IP address"
                               },
                               if: :server_address
    validates :server_address, uniqueness: true,
                               if: :correct_server_address?
    validates :thread_pool_size, numericality: {
                                   only_integer: true,
                                   greater_than: -2147483648,
                                   less_than: 2147483647
                                 }
    before_save :check_short_name

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :machine_affinity_slots,
      class_name: '::Naf::MachineAffinitySlot',
      dependent: :destroy
    has_many :affinities,
      through: :machine_affinity_slots

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.enabled
      return where(enabled: true)
    end

    def self.up
      return where(marked_down: false)
    end

    def self.down
      return where(marked_down: true)
    end

    def self.machine_ip_address
      return Socket::getaddrinfo(hostname, "echo", Socket::AF_INET)[0][3]
    rescue StandardError
      return "127.0.0.1"
    end

    def self.hostname
      Socket.gethostname
    rescue StandardError
      return "local"
    end

    def self.local_machine
      return where(:server_address => machine_ip_address).first
    end

    def self.current
      return local_machine
    end

    def self.last_time_schedules_were_checked
      return self.maximum(:last_checked_schedules_at)
    end

    def self.is_it_time_to_check_schedules?(check_period)
      time = Naf::Machine.last_time_schedules_were_checked
      return time.nil? || time < (Time.zone.now - check_period)
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def try_lock_for_runner_use(&block)
      return advisory_try_lock(&block)
    end

    def unlock_for_runner_use
      return advisory_unlock
    end

    def machine_logger
      return af_logger(self.class.name)
    end

    def to_s
      components = []
      if enabled
        components << "ENABLED"
      else
        components << "DISABLED"
      end
      if marked_down
        components << "DOWN!"
      end
      components << "id: #{id}"
      components << "address: #{server_address}"
      components << "name: \"#{server_name}\"" unless server_name.blank?
      components << "pool size: #{thread_pool_size}"
      components << "last checked schedules: #{last_checked_schedules_at}"
      components << "last seen: #{last_seen_alive_at}"

      return "::Naf::Machine<#{components.join(', ')}>"
    end

    def correct_server_address?
      server_address.present? and IP_REGEX =~ server_address
    end

    def mark_checked_schedule
      self.last_checked_schedules_at = Time.zone.now
      save!
    end

    def mark_alive
      self.last_seen_alive_at = Time.zone.now
      save!
    end

    def mark_up
      self.marked_down = false
      save!
    end

    def mark_down(by_machine)
      self.marked_down = true
      self.marked_down_by_machine_id = by_machine.id
      self.marked_down_at = Time.zone.now
      save!
    end

    def is_stale?(period)
      # if last_seen_alive_at is nil then the runner has not been started yet -- hold off
      # claiming it is stale until the runner is run at least once.
      return self.last_seen_alive_at.present? && self.last_seen_alive_at < (Time.zone.now - period)
    end

    def mark_processes_as_dead(by_machine)
      ::Naf::RunningJob.where(created_at: (Time.zone.now - Naf::HistoricalJob::JOB_STALE_TIME)..Time.zone.now).
        where("request_to_terminate = false").
        started_on(self).each do |job|

        marking_at = Time.zone.now
        machine_logger.alarm "#{by_machine.id} marking #{job} as dead at #{marking_at}"
        job.request_to_terminate = true
        job.marked_dead_by_machine_id = by_machine.id
        job.marked_dead_at = marking_at
        job.finished_at = marking_at
        job.save!
      end
    end

    def mark_machine_down(by_machine)
      marking_at = Time.zone.now
      machine_logger.alarm "#{by_machine.id} marking #{self} as down at #{marking_at}"
      self.marked_down = true
      self.marked_down_by_machine_id = by_machine.id
      self.marked_down_at = marking_at
      save!
      mark_processes_as_dead(by_machine)
    end

    def affinity
      return ::Naf::Affinity.find_by_affinity_classification_id_and_affinity_name(::Naf::AffinityClassification.location.id, server_address)
    end

    def short_name_if_it_exist
      short_name || server_name
    end

    private

    def check_short_name
      self.short_name = nil if self.short_name.blank?
      self.server_name = nil if self.server_name.blank?
      self.server_note = nil if self.server_note.blank?
      self.log_level = nil if self.log_level.blank?
    end

  end
end
