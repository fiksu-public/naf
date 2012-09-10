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
          job_hashes = Logical::Naf::Job.search(params[:search]).map(&:to_hash).map{|hash| add_application_url(hash)}
          render :json => {:job_root_url => naf.jobs_path, :cols => @cols, :jobs => job_hashes }.to_json
        end
      end
    end

    def show
      @record = Naf::Job.find(params[:id])
      @record = Logical::Naf::Job.new(@record)
      respond_to do |format|
        format.json do
          render :json => {:cols => @attributes, :job => @record.to_detailed_hash}.to_json
        end
        format.html do
          render :template => 'naf/record'
        end
      end
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
      @attributes = Logical::Naf::Job::ATTRIBUTES
      @cols = Logical::Naf::Job::COLUMNS
    end

    def add_application_url(hash)
      job = ::Naf::Job.find(hash[:id])
      if application = job.application
        hash[:application_url] = url_for(application)
      else
        hash[:application_url] = nil
      end
      return hash
    end

  end

  

end
