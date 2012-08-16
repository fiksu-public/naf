module Naf
  class ApplicationSchedulesController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::ApplicationSchedule.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationSchedule.find(params[:id])
      render :template => 'naf/record'
    end

    def new
      @application_schedule = Naf::ApplicationSchedule.new
    end

    def destroy
      @application_schedule = Naf::ApplicationSchedule.find(params[:id])
      @application_schedule.destroy
      redirect_to :action => 'index'
    end

    def create
      @application_schedule = Naf::ApplicationSchedule.new(params[:application_schedule])
      if  @application_schedule.save
        redirect_to(@application_schedule, :notice => 'Application Schedule was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @application_schedule = Naf::ApplicationSchedule.find(params[:id])
    end

    def update
      @application_schedule = Naf::ApplicationSchedule.find(params[:id])
      if @application_schedule.update_attributes(params[:application_schedule])
        redirect_to(@application_schedule, :notice => 'Application Schedule was successfully updated.') 
      else
        render :action => "edit"
      end
    end
    
    private
    
    def set_cols_and_attributes
      @cols = [:title, :application_run_group_name, :application_run_group_restriction_name, :run_interval, :priority, :enabled, :visible]
      @attributes = Naf::ApplicationSchedule.attribute_names.map(&:to_sym) | @cols
    end

  end
end
