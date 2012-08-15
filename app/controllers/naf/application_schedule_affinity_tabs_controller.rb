module Naf
  class ApplicationScheduleAffinityTabsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = []
      if params[:application_schedule_id]
        @rows = Naf::ApplicationScheduleAffinityTab.where(:application_schedule_id => params[:application_schedule_id])
      end
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      @application_schedule = Naf::ApplicationSchedule.find(params[:application_schedule_id])
      render :template => 'naf/record'
    end

    def destroy
      @tab = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      @tab.destroy
      redirect_to :action => 'index'
    end

    def new
      @application_schedule = Naf::ApplicationSchedule.find(params[:application_schedule_id])
      @tab = Naf::ApplicationScheduleAffinityTab.new
    end

    def create
      @application_schedule = Naf::ApplicationSchedule.find(params[:application_schedule_affinity_tab][:application_schedule_id])
      @tab = Naf::ApplicationScheduleAffinityTab.new(params[:application_schedule_affinity_tab])
      if @tab.save
        redirect_to({:action => 'show', :id => @tab.id, :application_schedule_id => @application_schedule.id}, :notice => 'Application Schedule Affinity Tab was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @tab = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      @application_schedule = Naf::ApplicationSchedule.find(@tab.application_schedule_id)
    end

    def update
      @tab = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      @application_schedule = Naf::ApplicationSchedule.find(@tab.application_schedule_id)
      if @tab.update_attributes(params[:application_schedule_affinity_tab])
        redirect_to({:action => 'show', :id => @tab.id, :application_schedule_id => @application_schedule.id}, :notice => 'Application Schedule Affinity Tab was successfully created  was successfully updated.') 
      else
        render :action => "edit", :application_schedule_id => @application_schedule.id
      end
    end


    
    private
    
    def set_cols_and_attributes
      @cols = [:script_title, :affinity_name, :affinity_classification_name]
      @attributes = Naf::ApplicationScheduleAffinityTab.attribute_names.map(&:to_sym) + @cols
    end



  end
end
