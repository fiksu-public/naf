require 'naf/version'

module Process::Naf
  class MachineUpgrader < ::Process::Naf::Application
    opt :upgrade_option,
        "what should we do",
        default: :dump,
        choices: [:dump, :restore]
    opt :pretty,
        "make things pretty",
        default: false
    opt :no_updates,
        "don't update the db (via transaction rollback)",
        default: false
    opt :force,
        "run even if system looks unclean",
        default: false

    PRESERVABLES = [
                    ::Naf::ApplicationType,
                    ::Naf::Application,
                    ::Naf::ApplicationRunGroupRestriction,
                    ::Naf::ApplicationSchedule,
                    ::Naf::ApplicationSchedulePrerequisite,
                    ::Naf::AffinityClassification,
                    ::Naf::Affinity,
                    ::Naf::ApplicationScheduleAffinityTab,
                    ::Naf::LoggerLevel,
                    ::Naf::LoggerName,
                    ::Naf::LoggerStyle,
                    ::Naf::LoggerStyleName,
                    ::Naf::Machine,
                    ::Naf::MachineAffinitySlot,
                    ::Naf::JanitorialAssignment
                   ]

    CLEAN_SYSTEM_MODELS = [
                           ::Naf::Machine,
                           ::Naf::VERSION == '1.0.1' ? ::Naf::HistoricalJob : ::Naf::Job
                          ]


    def work
      self.send("work_#{@upgrade_option}")
    end

    def work_dump
      pickler = ::Logical::Naf::Pickler.new(::Naf::VERSION, PRESERVABLES)
      pickler.preserve
      if @pretty
        puts JSON.pretty_generate(pickler.pickle_jar)
      else
        puts JSON.generate(pickler.pickle_jar)
      end
    end

    def work_restore
      begin
        pickle_jar = JSON.parse(STDIN.read)
      rescue StandardError => e
        logger.fatal "this doesn't look like a naf upgrade stream to me, it is not json parserable!"
        exit 1
      end

      unless pickle_jar.is_a?(Hash)
        logger.fatal "this doesn't look like a naf upgrade stream to me, it is of type: #{pickle_jar.class.name}"
        exit 1
      end

      pickle_jar_version = pickle_jar['version']
      if pickle_jar_version.blank?
        logger.fatal "this doesn't look like a naf upgrade stream to me, it has no version!"
        exit 1
      end

      preserves = pickle_jar['preserves']
      if preserves.nil?
        logger.fatal "this doesn't look like a naf upgrade stream to me, there are no preserves!"
        exit 1
      end

      unless preserves.is_a?(Hash)
        logger.fatal "this doesn't look like a naf upgrade stream to me, the preserves are type: #{preserves.class.name}"
        exit 1
      end

      check_for_clean_system unless @force

      preserved_at_text = pickle_jar['preserved_at']
      preserved_at = Time.parse(preserved_at_text) rescue "unknown"

      logger.info "restoring:"
      logger.info " preserved_at: #{preserved_at}"
      logger.info " version: #{pickle_jar_version}"
      logger.info " models: #{preserves.length}"

      unpickler = ::Logical::Naf::Unpickler.new(preserves, PRESERVABLES, pickle_jar_version)
      ::Naf::NafBase.transaction do
        unpickler.reconstitute
        raise ActiveRecord::Rollback if @no_updates
      end
      logger.info "restoration complete! thank you!"
    end

    def check_for_clean_system
      CLEAN_SYSTEM_MODELS.each do |model|
        raise "the system is unclean" if model.count > 0
      end
    end

  end
end
