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
  		elsif @rollback.present?
  			rollback_changes
  		end

  		logger.info 'Finished updating application schedules'
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
