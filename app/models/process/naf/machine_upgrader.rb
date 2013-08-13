require 'csv'

module Process::Naf
  class MachineUpgrader < ::Process::Naf::Application

    opt :upgrade_option, type: :string
    opt :naf_version, type: :string

    def work
      if @upgrade_option.present?
        if @upgrade_option == 'save'
          save_information('naf_tables_information_v_0_9_9.csv')
          save_information('naf_tables_information_v_1_0_0.csv')
        elsif @upgrade_option == 'restore'
          if @naf_version == '0.9.9'
            restore_information('naf_tables_information_v_0_9_9.csv')
          elsif @naf_version == '1.0.0'
            restore_information('naf_tables_information_v_1_0_0.csv')
          else
            logger.error 'Invalid version option. Please specify one of the following ' +
              'options: --naf-version 0.9.9, --naf-version 1.0.0'
          end
        else
          logger.error 'Invalid upgrade option. Please specify one of the following ' +
            'options: --upgrade-option save, --upgrade-option restore'
        end
      else
        logger.error 'Upgrade option missing. Please specify one of the following ' +
          'options: --upgrade-option save, --upgrade-option restore'
      end
    end

    private

    def save_information(file)
      logger.info "Saving information to file: #{file}"

      CSV.open(file, 'w') do |csv|
        # Traverse through all the necessary tables
        tables.each do |table|
          table.all.each do |record|
            # Information related to data inserted by the Naf migration should not be include in the CSV file.
            if !((table == ::Naf::Affinity && ['normal', 'canary', 'perennial'].include?(record.affinity_name)) ||
              (table == ::Naf::ApplicationSchedule && ['::Process::Naf::Janitor.run'].include?(record.application_run_group_name)) ||
              (table == ::Naf::Application && ['::Process::Naf::Janitor.run'].include?(record.command)))

              # Information will be saved with the format of table name, followed by
              # pairs of attribute name/value
              csv << [table.table_name]
              record.attributes.each do |key, value|
                # Certain attribute values do not need to be saved
                if !((table == ::Naf::Machine && machines_excluded_attributes.include?(key)) ||
                  (['created_at', 'updated_at'].include?(key)))

                  # Since version 1.0.0 has 5 default affinities and version
                  # 0.9.9 has 3 default affinities, the affinities ids need
                  # to be readjusted
                  if ((table == ::Naf::Affinity && key == 'id') ||
                      (key == 'affinity_id')) && @naf_version == '1.0.0'

                    csv << [key, value + 2]
                  else
                    csv << [key, value]
                  end
                end
              end
              csv << ['---']
            end
          end

          # No need to update the table sequence if it doesn't have any records
          if table.count != 0
            logger.info "Saved #{table.count} #{table.to_s} record(s)"

            # The affinity sequence needs to be readjusted for version 1.0.0
            if table == ::Naf::Affinity && @naf_version == '1.0.0'
              last_value = (table.
                find_by_sql("SELECT last_value FROM #{table.sequence_name}").
                first['last_value'].to_i + 2).to_s
              csv << [table.sequence_name, last_value]
            else
              csv << [table.sequence_name, table.find_by_sql("SELECT last_value FROM #{table.sequence_name}").first['last_value']]
            end
            csv << ['===']
          end
        end
      end

      logger.info 'Closing file'
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

    # Naf tables that has important information that needs to be saved before
    # reverting the migration
    def tables
      @tables ||= [
        ::Naf::Application,
        ::Naf::ApplicationSchedule,
        ::Naf::ApplicationSchedulePrerequisite,
        ::Naf::Affinity,
        ::Naf::ApplicationScheduleAffinityTab,
        ::Naf::LoggerName,
        ::Naf::LoggerStyle,
        ::Naf::LoggerStyleName,
        ::Naf::Machine,
        ::Naf::MachineAffinitySlot
      ]
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
