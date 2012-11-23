module Naf
  class ApplicationsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html do
        end
        format.json do
          set_page
          applications = []
          application = []
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
          @applications = applications.paginate(:page => @page, :per_page => @rows_per_page)
          render :layout => 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @record = Logical::Naf::Application.new(Naf::Application.find(params[:id]))
      render :template => 'naf/record'
    end

    def new
      @application = Naf::Application.new
      app_schedule = @application.build_application_schedule
      app_schedule.application_schedule_prerequisites.build
    end

    def create
      @application = Naf::Application.new(params[:application])
      if @application.save
        redirect_to(@application, :notice => "Application '#{@application.command}' was successfully created.")
      else
        render :action => "new"
      end
    end

    def edit
      @application = Naf::Application.find(params[:id])
      app_schedule = @application.application_schedule
      if app_schedule.blank?
        build_app_schedule = @application.build_application_schedule
        build_app_schedule.application_schedule_prerequisites.build
      else
        if app_schedule.application_schedule_prerequisites.blank?
          app_schedule.application_schedule_prerequisites.build
        end
      end
    end

    def update
      @application = Naf::Application.find(params[:id])
      if @application.update_attributes(params[:application])
        redirect_to(@application, :notice => "Application '#{@application.command}' was successfully updated.")
      else
        render :action => "edit"
      end
    end


    private

    def set_cols_and_attributes
      more_attributes = [:script_type_name, :application_run_group_name, :application_run_group_restriction_name, :run_interval, :run_start_minute, :priority, :application_run_group_limit, :visible, :enabled ]
      @attributes = Naf::Application.attribute_names.map(&:to_sym) | more_attributes
      @cols = Logical::Naf::Application::COLUMNS
    end

  end

end
