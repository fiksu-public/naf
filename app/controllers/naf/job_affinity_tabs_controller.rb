module Naf
  class JobAffinityTabsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = []
      if params[:job_id]
        @rows = Naf::JobAffinityTab.where(:job_id => params[:job_id])
      end
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::JobAffinityTab.find(params[:id])
      @job = Naf::Job.find(@record.job_id)
      render :template => 'naf/record'
    end

    def destroy
      @tab = Naf::JobAffinityTab.find(params[:id])
      @tab.destroy
      redirect_to :action => 'index'
    end

    def new
      @job = Naf::Job.find(params[:job_id])
      @tab = Naf::JobAffinityTab.new
    end

    def create
      @job = Naf::Job.find(params[:job_affinity_tab][:job_id])
      @tab = Naf::JobAffinityTab.new(params[:job_affinity_tab])
      if  @tab.save
        redirect_to({:action => 'show', :id => @tab.id, :job_id => @job.id}, :notice => 'Job Affinity Tab was successfully created.') 
      else
        render :action => "new", :job_id => @job.id
      end
    end

    def edit
      @tab = Naf::JobAffinityTab.find(params[:id])
      @job = Naf::Job.find(@tab.job_id)
    end

    def update
      @tab = Naf::JobAffinityTab.find(params[:id])
      @job = Naf::Job.find(@tab.job_id)
      if @tab.update_attributes(params[:job_affinity_tab])
        redirect_to({:action => 'show', :id => @tab.id, :job_id => @job.id}, :notice => 'Job Affinity Tab was successfully created  was successfully updated.') 
      else
        render :action => "edit", :job_id => @job.id
      end
    end


    
    private
    
    def set_cols_and_attributes
      @cols = [:title, :script_type_name, :command, :affinity_name, :affinity_classification_name]
      @attributes = Naf::JobAffinityTab.attribute_names.map(&:to_sym) | @cols
    end



  end
end
