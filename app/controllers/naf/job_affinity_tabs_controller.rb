module Naf
  class JobAffinityTabsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::JobAffinityTab.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::JobAffinityTab.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @tab = Naf::JobAffinityTab.find(params[:id])
      @tab.destroy
      redirect_to :action => 'index'
    end

    def new
      @tab = Naf::JobAffinityTab.new
    end


    def create
      @tab = Naf::JobAffinityTab.new(params[:job_affinity_tab])
      if  @tab.save
        redirect_to(@tab, :notice => 'Job Affinity Tab was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @tab = Naf::JobAffinityTab.find(params[:id])
    end

    def update
      @tab = Naf::JobAffinityTab.find(params[:id])
      if @tab.update_attributes(params[:job_affinity_tab])
        redirect_to(@tab, :notice => 'Job Affinity Tab was successfully updated.') 
      else
        render :action => "edit"
      end
    end


    
    private
    
    def set_cols_and_attributes
      @cols = [:application_name, :script_type_name, :command, :affinity_name, :affinity_classification_name]
      @attributes = Naf::JobAffinityTab.attribute_names.map(&:to_sym) + @cols
    end



  end
end
