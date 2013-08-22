require 'naf/version'

module Process::Naf
  class MachineUpgrader < ::Process::Naf::Application
    UPGRADE_OPTIONS = [:dump, :restore]
    opt :upgrade_option, "what should we do", :default => :dump, :choices => UPGRADE_OPTIONS
    opt :pretty, "make things pretty", :default => false
    opt :no_updates, "don't update the db (via transaction rollback)", :default => false
    opt :force, "run even if system looks unclean", :defatul => false

    PRESERVABLES = [
                    ::Naf::ApplicationType,
                    ::Naf::Application,
                    ::Naf::ApplicationRunGroupRestriction,
                    ::Naf::ApplicationSchedule,
                    ::Naf::ApplicationSchedulePrerequisite,
                    ::Naf::AffinityClassification,
                    ::Naf::Affinity,
                    ::Naf::ApplicationScheduleAffinityTab,
                    ::Naf::LoggerName,
                    ::Naf::LoggerStyle,
                    ::Naf::LoggerStyleName,
                    ::Naf::Machine,
                    ::Naf::MachineAffinitySlot
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
      PRESERVABLES.each do |model|
        raise "the system is unclean" if model.count > 0
      end
    end

    def restore_information(file)
      record = nil
      attributes = nil

      CSV.open(file, 'r') do |csv|
        csv.read.each do |row|
          # End of attributes
          if row[0] == '---'
            # Assign all the values
            attributes.each do |key, value|
              record.send("#{key}=", value)
            end
            record.save!
            logger.info "Restored #{record.class.to_s}"
          # Table sequence
          elsif row[0] =~ /id_seq/
            # Restore the correct sequence value
            record.class.find_by_sql("SELECT setval('#{row[0]}', #{row[1].to_i})")
            logger.info "Restored #{row[0]}"
          # Table
          elsif row[0] =~ /naf./
            # Create a new record
            record = ('Naf::' + row[0].classify).constantize.new
            attributes = {}
          # Table attribute
          elsif row[0] != '==='
            # Populate a hash with attributes and values
            attributes[row[0].to_sym] = row[1]
          end
        end
      end
    end

    def machines_excluded_attributes
      @exclusions ||= [
        'created_at',
        'updated_at',
        'last_checked_schedules_at',
        'last_seen_alive_at',
        'marked_down',
        'marked_down_by_machine_id',
        'marked_down_at'
      ]
    end

  end
end
