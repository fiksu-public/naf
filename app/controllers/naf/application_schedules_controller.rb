module Naf
  class ApplicationSchedulesController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
    before_filter :coerce_start_run_minute, :only => [:create, :update]
  
    def index
      @rows = Naf::ApplicationSchedule.where(:application_id => params[:application_id])
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationSchedule.find(params[:id])
      render :template => 'naf/record'
    end

    def new
      @application = Naf::Application.find(params[:application_id])
      @application_schedule = Naf::ApplicationSchedule.new
    end

    def destroy
      @application_schedule = Naf::ApplicationSchedule.find(params[:id])
      @application = @application_schedule.application
      @application_schedule.destroy
      redirect_to :action => 'index', :application_id => @application.id
    end

    def create
      @application = Naf::Application.find(params[:application_id])
      @application_schedule = Naf::ApplicationSchedule.new(params[:application_schedule])
      if  @application_schedule.save
        redirect_to(application_application_schedule_path(@application, @application_schedule), :notice => 'Application Schedule was successfully created.') 
      else
        render :action => "new", :application_id => @application.id
      end
    end

    def edit
      @application = Naf::Application.find(params[:application_id])
      @application_schedule = Naf::ApplicationSchedule.find(params[:id])
    end

    def update
      @application = Naf::Application.find(params[:application_id])
      @application_schedule = Naf::ApplicationSchedule.find(params[:id])
      if @application_schedule.update_attributes(params[:application_schedule])
        redirect_to(application_application_schedule_path(@application, @application_schedule), :notice => 'Application Schedule was successfully updated.')
      else
        render :action => "edit", :id => @application_schedule.id, :application_id => @application.id
      end
    end
    
    private
    
    def set_cols_and_attributes
      @cols = [:title, :application_run_group_name, :application_run_group_restriction_name, :run_interval, :priority, :enabled, :visible]
      @attributes = Naf::ApplicationSchedule.attribute_names.map(&:to_sym) | @cols
    end

    def coerce_start_run_minute
      time_text = params[:application_schedule][:run_start_minute]
      
      unless time_text.blank?
        begin
          minutes_since_midnight = (Time.parse(time_text).seconds_since_midnight / 60).to_i
          params[:application_schedule][:run_start_minute] = minutes_since_midnight
        rescue ArgumentError
        end
      end
    end

  end
end
