module Naf
  class ApplicationScheduleAffinityTabsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::ApplicationScheduleAffinityTab.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @tab = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      @tab.destroy
      redirect_to :action => 'index'
    end

    def new
      @tab = Naf::ApplicationScheduleAffinityTab.new
    end


    def create
      @tab = Naf::ApplicationScheduleAffinityTab.new(params[:application_schedule_affinity_tab])
      if  @tab.save
        redirect_to(@tab, :notice => 'Application Schedule Affinity Tab was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @tab = Naf::ApplicationScheduleAffinityTab.find(params[:id])
    end

    def update
      @tab = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      if @tab.update_attributes(params[:application_schedule_affinity_tab])
        redirect_to(@tab, :notice => 'Application was successfully updated.') 
      else
        render :action => "edit"
      end
    end


    
    private
    
    def set_cols_and_attributes
      @cols = [:script_title, :affinity_name, :affinity_classification_name]
      @attributes = Naf::ApplicationScheduleAffinityTab.attribute_names.map(&:to_sym) + @cols
    end



  end
end
