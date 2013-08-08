module Naf
  class ApplicationsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html
        format.json do
          set_page

          applications = []
          application = []
          params[:search][:visible] = params[:search][:visible] ? false : true
          params[:search][:deleted] = params[:search][:deleted] ? false : "false"
          @total_records = Naf::Application.count(:all)
          Logical::Naf::Application.search(params[:search]).map(&:to_hash).map do |hash|
            hash.map do |key, value|
              value = '' if value.nil?
              application << value
            end
            applications << application
            application =[]
          end
          @total_display_records = applications.count
          @applications = applications.paginate(page: @page, per_page: @rows_per_page)

          render layout: 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @application = Naf::Application.find(params[:id])
      @logical_application = Logical::Naf::Application.new(@application)
    end

    def new
      @application = Naf::Application.new
      app_schedule = @application.build_application_schedule
      app_schedule.application_schedule_prerequisites.build
    end

    def create
      set_application_run_group_name
      @application = Naf::Application.new(params[:application])
      if @application.save
        app_schedule = @application.application_schedule
        if app_schedule.present?
          prerequisites =
          app_schedule.prerequisites.map do |prerequisite|
            prerequisite.title
          end.join(', ')
        end
        redirect_to(@application,
                    notice: "Application #{@application.title} was successfully created. #{'Prerequisites: ' + prerequisites if app_schedule.try(:prerequisites).try(:present?) }")
      else
        set_shown_schedule_and_prerequisite
        @application.build_application_schedule unless params[:application].try(:[], :application_schedule_attributes).try(:[], :_destroy) == "0"
        render action: "new"
      end
    end

    def edit
      @application = Naf::Application.find(params[:id])
      check_application_run_group_name
      app_schedule = @application.application_schedule
      if app_schedule.blank?
        build_app_schedule = @application.build_application_schedule
        build_app_schedule.application_schedule_prerequisites.build
      else
        @show_app_schedule = true
        if app_schedule.application_schedule_prerequisites.blank?
          app_schedule.application_schedule_prerequisites.build
        else
          @show_prerequisite = true
        end
      end
    end

    def update
      set_application_run_group_name
      @application = Naf::Application.find(params[:id])
      if @application.update_attributes(params[:application])
        app_schedule = @application.application_schedule
        if app_schedule.present?
          prerequisites =
          app_schedule.prerequisites.map do |prerequisite|
            prerequisite.title
          end.join(', ')
        end
        redirect_to(@application,
                    notice: "Application #{@application.title} was successfully updated. #{'Prerequisites: ' + prerequisites if app_schedule.try(:prerequisites).try(:present?) }")
      else
        set_shown_schedule_and_prerequisite
        render action: "edit"
      end
    end


    private

    def set_cols_and_attributes
      more_attributes = [:script_type_name, :application_run_group_name, :application_run_group_restriction_name, :run_interval, :run_start_minute, :priority, :application_run_group_limit, :visible, :enabled ]
      @attributes = Naf::Application.attribute_names.map(&:to_sym) | more_attributes
      @cols = Logical::Naf::Application::COLUMNS
    end

    def set_application_run_group_name
      @run_group_name_type = params[:run_group_name_type]
      case @run_group_name_type
        when "command"
          params[:application][:application_schedule_attributes][:application_run_group_name] = params[:application][:command]
        when "not set"
          params[:application][:application_schedule_attributes][:application_run_group_name] = nil
      end
    end

    def check_application_run_group_name
      case @application.application_schedule.try(:application_run_group_name)
        when @application.command
          @run_group_name_type = "command"
        when nil, ''
          @run_group_name_type = "not set"
        else
          @run_group_name_type = "custom"
      end
    end

    def set_shown_schedule_and_prerequisite
      if params[:application].try(:[], :application_schedule_attributes).try(:[], :_destroy) == "0"
        @show_app_schedule = true
        unless params[:application].try(:[], :application_schedule_attributes).
               try(:[], :application_schedule_prerequisites_attributes).
               try(:select) do |key, value|
                  value.try(:[], :_destroy) == "false"
               end.blank?
          @show_prerequisite = true
        end
      end
    end

  end

end
