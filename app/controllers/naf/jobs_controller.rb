module Naf
  class JobsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    def index
      respond_to do |format|
        format.html do 
          @rows = []
          render :template => 'naf/datatable'
        end
        format.json do
          job_hashes = Logical::Job.search(params[:search]).map(&:to_hash)
          render :json => {:job_root_url => naf.jobs_path, :cols => @cols, :jobs => job_hashes }.to_json
        end
      end
    end

    def show
      @record = Naf::Job.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @job = Naf::Job.find(params[:id])
      @job.destroy
      redirect_to :action => 'index'
    end

    def create
     @job = Naf::Job.new(params[:job])
     if params[:job][:application_id] and app = Naf::Application.find(params[:job][:application_id])
       @job.command = app.command
       @job.application_type_id = app.application_type_id
       post_source = "Application: #{app.title}"
     else
       post_source = "Job"
     end
      respond_to do |format|
        format.json do
          response = {}
          if @job.save
            response[:job_url] = url_for(@job)
            response[:post_source] = post_source
            response[:saved] = true
          else
            response[:saved] = false
            response[:errors] = @job.errors.full_messages
          end
          puts response
          render :json => response.to_json
        end
      end
    end

    def edit
      @job = Naf::Job.find(params[:id])
    end

    def update
      @job = Naf::Job.find(params[:id])
      if @job.update_attributes(params[:job])
        redirect_to(@job, :notice => 'Job was successfully updated.') 
      else
        render :action => "edit"
      end
    end


    private

    def set_cols_and_attributes
      more_attributes = [:title, :command, :script_type_name, :machine_started_on_server_address, :machine_started_on_server_name, :application_run_group_restriction_name]
      @attributes = Naf::Job.attribute_names.map(&:to_sym) | more_attributes
      @cols = [:id, :status, :queued_time, :title, :started_at, :finished_at, :pid, :server]
    end

  end

  

end
