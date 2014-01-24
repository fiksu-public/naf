module Naf
  class ApplicationSchedulesController < Naf::ApplicationController

    def index
      respond_to do |format|
        format.html
        format.json do
          application_schedules = []
          application_schedule = []
          @total_records = Naf::ApplicationSchedule.count(:all)
          Logical::Naf::ApplicationSchedule.search(params).map(&:to_hash).map do |hash|
            hash.map do |key, value|
              value = '' if value.nil?
              application_schedule << value
            end
            application_schedules << application_schedule
            application_schedule = []
          end

          @total_display_records = application_schedules.count
          @application_schedules = application_schedules.paginate(page: @page, per_page: @rows_per_page)

          render layout: 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      schedule = ::Naf::ApplicationSchedule.find(params[:id])
      @application_schedule = ::Logical::Naf::ApplicationSchedule.new(schedule)
    end

    def new
      @application_schedule = Naf::ApplicationSchedule.new(application_id: params[:application_id])
    end

    def create
      @application_schedule = Naf::ApplicationSchedule.new(params[:application_schedule])
      check_application_run_group_name
      set_application_run_group_name
      if @application_schedule.save
        redirect_to(@application_schedule.application, notice: "Application Schedule was successfully created.")
      else
        render action: :new
      end
    end

    def edit
      @application_schedule = ::Naf::ApplicationSchedule.find(params[:id])
      check_application_run_group_name
      if @application_schedule.application_schedule_prerequisites.blank?
        @application_schedule.application_schedule_prerequisites.build
      else
        @show_prerequisite = true
      end
    end

    def update
      @application_schedule = ::Naf::ApplicationSchedule.find(params[:id])
      set_application_run_group_name
      if @application_schedule.update_attributes(params[:application_schedule])
        redirect_to(@application_schedule, notice: "Application Schedule was successfully updated.")
      else
        render action: :edit
      end
    end

    def destroy
      @application_schedule = ::Naf::ApplicationSchedule.find(params[:id])
      @application_schedule.destroy
      flash[:notice] = 'Application Schedule was successfully deleted.'
      redirect_to action: :index
    end

    def check_application_run_group_name
      case @application_schedule.application_run_group_name
        when @application_schedule.application.command
          @run_group_name_type = 'command'
        when nil, ''
          @run_group_name_type = 'not set'
        else
          @run_group_name_type = 'custom'
      end
    end

    def set_application_run_group_name
      run_group_name_type = params[:run_group_name_type]
      case run_group_name_type
        when 'command'
          params[:application_schedule][:application_run_group_name] =
            ::Naf::Application.find_by_id(params[:application_schedule][:application_id]).command
        when 'not set'
          params[:application_schedule][:application_run_group_name] = nil
      end
    end

  end
end
