module Naf
  class JobAffinityTabsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      if params[:job_id]
        @tabs = Naf::JobAffinityTab.where(:job_id => params[:job_id])
      end
    end
    
    def show
      @record = Naf::JobAffinityTab.find(params[:id])
      @job =    Naf::Job.find(params[:job_id])
      render :template => 'naf/record'
    end

    def destroy
      @job = Naf::Job.find(params[:job_id])
      @tab = Naf::JobAffinityTab.find(params[:id])
      @tab.destroy
      redirect_to job_job_affinity_tabs_path(@job)
    end

    def new
      @job = Naf::Job.find(params[:job_id])
      @tab = Naf::JobAffinityTab.new
    end

    def create
      @job = Naf::Job.find(params[:job_id])
      @tab = Naf::JobAffinityTab.new(params[:job_affinity_tab])
      if  @tab.save
        redirect_to(job_job_affinity_tab_path(@job, @tab), :notice => 'Job Affinity Tab was successfully created.') 
      else
        render :action => "new", :job_id => @job.id
      end
    end

    def edit
      @job = Naf::Job.find(params[:job_id])
      @tab = Naf::JobAffinityTab.find(params[:id])
    end

    def update
      @job = Naf::Job.find(params[:job_id])
      @tab = Naf::JobAffinityTab.find(params[:id])
      if @tab.update_attributes(params[:job_affinity_tab])
        redirect_to(job_job_affinity_tab_path(@job, @tab), :notice => 'Job Affinity Tab was successfully created  was successfully updated.') 
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
