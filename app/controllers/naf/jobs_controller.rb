module Naf
  class JobsController < Naf::ApplicationController

    include Naf::ApplicationHelper

    before_filter :set_cols_and_attributes
    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        set_status
        format.html do
        end
        format.json do
          set_page
          params[:search][:direction] = params['sSortDir_0']
          params[:search][:order] = Logical::Naf::Job::ORDER[params['iSortCol_0']]
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
      @job = Naf::Job.new
    end

    def create
      set_application_run_group_name
      @job = Naf::Job.new(params[:job])
      if params[:job][:application_id] && app = Naf::Application.find(params[:job][:application_id])
        if schedule = app.application_schedule
          @job = Logical::Naf::JobCreator.new.queue_application_schedule(schedule)
        else
          @job.command = app.command
          @job.application_type_id = app.application_type_id
          @job.application_run_group_restriction_id = Naf::ApplicationRunGroupRestriction.no_limit.id
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
      check_application_run_group_name
    end

    def update
      respond_to do |format|
        set_application_run_group_name
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
      hash[:papertrail_url] = naf_papertrail_link(job)
      return hash
    end

    def set_application_run_group_name
      @run_group_name_type = params[:run_group_name_type]
      case @run_group_name_type
        when "command"
          params[:job][:application_run_group_name] = params[:job][:command]
        when "not set"
          params[:job][:application_run_group_name] = nil
      end
    end

    def check_application_run_group_name
      case @job.application_run_group_name
        when @job.command
          @run_group_name_type = "command"
        when nil, ''
          @run_group_name_type = "not set"
        else
          @run_group_name_type = "custom"
      end
    end

    def set_status
      if params[:search].try(:[], :status).present?
        @status = (params[:search][:status] or "queued").to_sym
      elsif cookies[:search_status].present?
        @status = cookies[:search_status].to_sym
      else
        @status = :queued
      end
      cookies[:search_status] = @status
    end

  end

end
