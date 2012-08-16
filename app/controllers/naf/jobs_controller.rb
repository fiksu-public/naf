module Naf
  class JobsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    FILTER_FIELDS = [:application_type_id, :application_run_group_restriction_id, :priority, :failed_to_start, :pid, :exit_status, :request_to_terminate, :started_on_machine_id]
 
    SEARCH_FIELDS = [:command, :application_run_group_name]

    def index
      respond_to do |format|
        format.html do 
          @jobs_page = "Hi I'm over here"
          @rows = []
          render :template => 'naf/datatable'
        end
        format.json do
          order, direction = params[:search][:order], params[:search][:direction]
          job_scope = Naf::Job.order("#{order} #{direction}").limit(10)
          if params[:search][:running].present? and running = params[:search][:running] == "true"
            if running
              job_scope = job_scope.where("started_on_machine_id is not null")
            else
              job_scope = job_scope.where("started_on_machine_id is null")
            end
          end
          FILTER_FIELDS.each do |f|
            job_scope = job_scope.where(f => params[:search][f]) if params[:search][f].present?
          end
          SEARCH_FIELDS.each do |f|
            job_scope = job_scope.where(["lower(#{f}) ~ ?", params[:search][f].downcase]) if params[:search][f].present?
          end
          methods =  [:title, :script_type_name, :application_run_group_restriction_name, :machine_started_on_server_name, :machine_started_on_server_address]
          jobs_hashes = job_scope.as_json(:methods => methods)
          jobs_hashes.each do |job_hash|
            job_hash.each do |key, value| 
              if value.kind_of?(Time)
                job_hash[key] = value.strftime("%Y-%m-%d %H:%M:%S") 
              end
            end
          end
          render :json => {:job_root_url => naf.jobs_path, :cols => @cols, :jobs => jobs_hashes }.to_json
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
      @cols = [:created_at, :title, :command, :script_type_name, :application_run_group_name, :application_run_group_restriction_name, :priority, :failed_to_start, :started_at, :finished_at, :pid, :exit_status, :request_to_terminate,  :machine_started_on_server_name, :machine_started_on_server_address]
    end

  end

  

end
