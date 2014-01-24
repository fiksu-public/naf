module Process::Naf::DataMigration
  class BackfillApplicationScheduleRunInterval < ::Process::Naf::Application

    opt :update, 'update run interval styles id'
    opt :rollback, 'rollback changes'
    opt_select :update_or_rollback, one_of: [:update, :rollback]

    attr_reader :run_interval_styles

    def work
      logger.info 'Starting to update application schedules...'

      if @update.present?
        setup
        update_run_interval_styles_ids
        logger.info 'Finished updating application schedules'
      elsif @rollback.present?
        if validate_applications
          rollback_changes
          logger.info 'Finished updating application schedules'
        end
      end
    end

    private

    def setup
      @run_interval_styles = {}
      ::Naf::RunIntervalStyle.all.each do |ris|
        @run_interval_styles[ris.name] = ris.id
      end
    end

    def update_run_interval_styles_ids
      ::Naf::ApplicationSchedule.all.each do |schedule|
        logger.info "Updating application schedule: #{schedule.id}"

        if schedule.run_start_minute.present?
          schedule.run_interval = schedule.run_start_minute
          schedule.run_interval_style_id = run_interval_styles['at beginning of day']
        elsif schedule.run_interval.present?
          schedule.run_interval_style_id = run_interval_styles['after previous run']
        else
          schedule.run_interval = 0
          schedule.run_interval_style_id = run_interval_styles['at beginning of day']
        end

        schedule.save!
      end
    end

    def validate_applications
      applications = []
      ::Naf::Application.all.each do |application|
        if application.application_schedules.count > 1
          applications << application.title
        end
      end

      if applications.present?
        logger.warn "The following applications have more than one schedule: #{applications.join(', ')}. " +
        "In order to rollback successfully, an application can have at most one schedule."
        return false
      else
        return true
      end
    end

    def rollback_changes
      ::Naf::ApplicationSchedule.all.each do |schedule|
        logger.info "Updating application schedule: #{schedule.id}"

        if schedule.run_interval_style.name == 'at beginning of day'
          schedule.run_start_minute = schedule.run_interval
          schedule.run_interval = nil
        else
          schedule.run_start_minute = nil
        end

        schedule.save!
      end
    end

  end
end
