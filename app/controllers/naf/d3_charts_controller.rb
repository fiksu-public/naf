module Naf
  class D3ChartsController < Naf::ApplicationController

    def jobs
      get_form_options

      respond_to do |format|
        format.html
        format.json {
          queued = ::Logical::Naf::RangedData.new(@grouping)
          running = ::Logical::Naf::RangedData.new(@grouping)
          errored = ::Logical::Naf::RangedData.new(@grouping)

          min_time = max_time = Time.zone.now
          ::Naf::HistoricalJob.
          select("date_trunc('#{@grouping}', created_at) as created_at,date_trunc('#{@grouping}', started_at) as started_at," +
            "date_trunc('#{@grouping}', finished_at) as finished_at,failed_to_start,exit_status").
          each do |j1|
            queued_at = j1.created_at
            finished_at = (j1.finished_at || Time.zone.now)
            started_at = j1.started_at

            if queued_at < min_time
              min_time = queued_at
            end
            if finished_at < min_time
              min_time = finished_at
            end
            if started_at && started_at < min_time
              min_time = started_at
            end

            queued.add_range(queued_at, finished_at)
            if j1.failed_to_start && started_at && finished_at
              errored.add_range(started_at, finished_at)
            else
              running.add_range(started_at, finished_at) if started_at
              if (j1.exit_status||0) > 0
                errored.add_range(finished_at, finished_at)
              end
            end
          end

          @chart_data = []

          queued_data = queued.ranged_data(@start_datetime, @end_datetime)
          running_data = running.ranged_data(@start_datetime, @end_datetime)
          errored_data = errored.ranged_data(@start_datetime, @end_datetime)
          ::Logical::Naf::RangedData.time_range(@start_datetime, @end_datetime, @grouping).each_with_index do |time_value, index|
            @chart_data << {
              date: time_value,
              queued: queued_data[index],
              running: running_data[index],
              errored: errored_data[index]
            }
          end

          max = [ queued_data, running_data, errored_data ].flatten.max

          step = max / 10
          step = 1 if step == 0

          @scale_step_width = step
          @scale_steps = 10

          steps_to_show_day = 0
          steps_to_show_label = 0

          @total_display_records = @total_records = @chart_data.length
          render json: @chart_data.to_json
        }
      end
    end

    def runner_jobs
      get_form_options

      respond_to do |format|
        format.html
        format.json {
          running = {}

          min_time = max_time = Time.zone.now
          ::Naf::HistoricalJob.
          select("date_trunc('#{@grouping}', created_at) as created_at,date_trunc('#{@grouping}', started_at) as started_at," +
            "date_trunc('#{@grouping}', finished_at) as finished_at,started_on_machine_id").
          where("started_at is not null").each do |j1|
            finished_at = (j1.finished_at || Time.zone.now)
            started_at = j1.started_at
            if finished_at < min_time
              min_time = finished_at
            end
            if started_at < min_time
              min_time = started_at
            end

            running[j1.started_on_machine_id] ||= ::Logical::Naf::RangedData.new(@grouping)
            running[j1.started_on_machine_id].add_range(started_at, finished_at)
          end

          @chart_data = []
          machines = {}
          running.keys.map do |machine_id|
            machine = ::Naf::Machine.where(id: machine_id).first
            machines[machine_id] = (machine.short_name || machine.server_name)
          end

          running_data = {}
          running.each do |machine_id,data_machine|
            running_data[machine_id] = data_machine.ranged_data(min_time, max_time)
          end

          ::Logical::Naf::RangedData.time_range(min_time, max_time, @grouping).each_with_index do |time_value, index|
            datum = {
              date: time_value
            }
            machines.each do |machine_id, machine_name|
              datum[machine_name] = running_data[machine_id][index]
            end
            @chart_data << datum
          end

          render json: @chart_data.to_json
        }
      end
    end

    def errored_jobs
      get_form_options

      respond_to do |format|
        format.html
        format.json {
          errored = {}

          min_time = max_time = Time.zone.now
          ::Naf::HistoricalJob.
          select("date_trunc('#{@grouping}', created_at) as created_at,date_trunc('#{@grouping}', started_at) as started_at," +
            "date_trunc('#{@grouping}', finished_at) as finished_at,started_on_machine_id").
          where("finished_at is not null and exit_status > 0 and started_on_machine_id is not null").each do |j1|
            finished_at = j1.finished_at
            if finished_at < min_time
              min_time = finished_at
            end

            errored[j1.started_on_machine_id] ||= ::Logical::Naf::RangedData.new(@grouping)
            errored[j1.started_on_machine_id].add_range(finished_at, finished_at)
          end

          @chart_data = []
          machines = {}
          errored.keys.map do |machine_id|
            machine = ::Naf::Machine.where(id: machine_id).first
            machines[machine_id] = (machine.short_name || machine.server_name)
          end

          errored_data = {}
          errored.each do |machine_id,data_machine|
            errored_data[machine_id] = data_machine.ranged_data(min_time, max_time)
          end

          ::Logical::Naf::RangedData.time_range(min_time, max_time, @grouping).each_with_index do |time_value, index|
            datum = {
              date: time_value
            }
            machines.each do |machine_id, machine_name|
              datum[machine_name] = errored_data[machine_id][index]
            end
            @chart_data << datum
          end

          render json: @chart_data.to_json
        }
      end
    end

    def running_scripts
      get_form_options

      respond_to do |format|
        format.html
        format.json {
          running = {}

          min_time = @start_datetime
          max_time = @end_datetime
          ::Naf::HistoricalJob.select("substring(command from '^[^ ]+') as command,date_trunc('#{@grouping}', created_at) as created_at," +
            "date_trunc('#{@grouping}', started_at) as started_at,date_trunc('#{@grouping}', finished_at) as finished_at").
          where("started_at is not null").each do |j1|
            finished_at = (j1.finished_at || Time.zone.now)
            started_at = j1.started_at
            if finished_at < min_time
              min_time = finished_at
            end
            if started_at < min_time
              min_time = started_at
            end

            running[j1.command] ||= ::Logical::Naf::RangedData.new(@grouping)
            running[j1.command].add_range(started_at, finished_at)
          end

          @chart_data = []
          running_data = {}
          running.each do |command,data_machine|
            running_data[command] = data_machine.ranged_data(min_time, max_time)
          end

          ::Logical::Naf::RangedData.time_range(min_time, max_time, @grouping).each_with_index do |time_value, index|
            datum = {
              date: time_value
            }
            running.keys.each do |command|
              datum[command] = running_data[command][index]
            end
            @chart_data << datum
          end

          render json: @chart_data.to_json
        }
      end
    end

    def get_form_options
      options = params['graph_options']
      if options.present?
        if options['start_datetime'].present?
          @start_datetime = Time.zone.parse(options['start_datetime']) rescue Time.zone.now - 2.days
        end
        if options['end_datetime'].present?
          @end_datetime = Time.zone.parse(options['end_datetime']) rescue Time.zone.now
        end
        @grouping = options['grouping']
      else
        @start_datetime = Time.zone.now - 2.days
        @end_datetime = Time.zone.now
        @grouping = "hour"
      end
      @url_params = "graph_options[start_datetime]=#{@start_datetime}&graph_options[end_datetime]=#{@end_datetime}&graph_options[grouping]=#{@grouping}"
    end

  end
end
