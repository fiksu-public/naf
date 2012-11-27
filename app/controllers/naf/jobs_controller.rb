module Naf
  class JobsController < Naf::ApplicationController

    include Naf::ApplicationHelper

    before_filter :set_cols_and_attributes
    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html do
        end
        format.json do
          set_page
          params[:search][:limit] = params['iDisplayLength']
          params[:search][:offset] = @page - 1
          @total_display_records = Logical::Naf::Job.total_display_records(params[:search])
          @total_records = Naf::Job.count(:all)
          @jobs = []
          job =[]
          Logical::Naf::Job.search(params[:search]).map(&:to_hash).map do |hash|
            add_urls(hash).map do |key, value|
              value ||= ''
              job << value
            end
            @jobs << job
            job = []
          end
          render :layout => 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @record = Naf::Job.find(params[:id])
      @record = Logical::Naf::Job.new(@record)
      respond_to do |format|
        format.json do
          render :json => { :success => true }.to_json
        end
        format.html do
          render :template => 'naf/record'
        end
      end
    end

    def new
    end

    def create
      @job = Naf::Job.new(params[:job])
      if params[:job][:application_id] && app = Naf::Application.find(params[:job][:application_id])
        if schedule = app.application_schedule
          @job = Logical::Naf::JobCreator.new.queue_application_schedule(schedule)
        else
          @job.command = app.command
          @job.application_type_id = app.application_type_id
          @job.application_run_group_restriction_id = Naf::ApplicationRunGroupRestriction.no_limit.id
          @job.application_run_group_name = "Manually Enqueued Group"
          @job.application_run_group_limit = 1
        end
      end
      respond_to do |format|
        format.json do
          render :json => {
                            :success => true,
                            :title => @job.title,
                            :command => @job.command,
                           }.to_json if @job.save
        end
        format.html do
          if @job.save
            redirect_to(@job, :notice => "Job '#{@job.command}' was successfully created.")
          else
            render :action => "new"
          end
        end
      end
    end

    def edit
      @job = Naf::Job.find(params[:id])
    end

    def update
      respond_to do |format|
        @job = Naf::Job.find(params[:id])
        if @job.update_attributes(params[:job])
          format.html do
            redirect_to(@job, :notice => "Job '#{@job.command}' was successfully updated.")
          end
          format.json do
            render :json => { :success => true, :title => @job.title, :command => @job.command }.to_json
          end
        else
          format.html do 
            render :action => "edit"
          end
          format.json do
            render :json => {:success => false}.to_json
          end
        end
      end
    end


    private

    def set_cols_and_attributes
      @attributes = Logical::Naf::Job::ATTRIBUTES
    end

    def add_urls(hash)
      job = ::Naf::Job.find(hash[:id])
      if application = job.application
        hash[:application_url] = url_for(application)
      else
        hash[:application_url] = nil
      end
      hash[:papertrail_url] = papertrail_link(job)
      return hash
    end

  end

end
