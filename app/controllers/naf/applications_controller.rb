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
          Logical::Naf::Application.all.map(&:to_hash).map do |hash|
            hash.map do |key, value|
              value = '' if value.nil?
              application << value
            end
            applications << application
            application =[]
          end
          @applications = applications.paginate(:page => @page, :per_page => @rows_per_page)
          render :layout => 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @record = Logical::Naf::Application.new(Naf::Application.find(params[:id]))
      render :template => 'naf/record'
    end

    def destroy
      @application = Naf::Application.find(params[:id])
      @application.destroy
      redirect_to naf.applications_path
    end

    def new
      @application = Naf::Application.new
      @application.build_application_schedule
    end

    def create
      @application = Naf::Application.new(params[:application])
      if @application.save
        redirect_to(@application, :notice => 'Application was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @application = Naf::Application.find(params[:id])
      @application.build_application_schedule if @application.application_schedule.blank?
    end

    def update
      @application = Naf::Application.find(params[:id])
      if @application.update_attributes(params[:application])
        redirect_to(@application, :notice => 'Application was successfully updated.') 
      else
        render :action => "edit"
      end
    end


    private

    def set_cols_and_attributes
      more_attributes = [:script_type_name, :application_run_group_name, :application_run_group_restriction_name, :run_interval, :run_start_minute, :priority, :visible, :enabled ]
      @attributes = Naf::Application.attribute_names.map(&:to_sym) | more_attributes
      @cols = Logical::Naf::Application::COLUMNS
    end

  end

end
