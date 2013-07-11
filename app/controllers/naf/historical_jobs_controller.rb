module Naf
  class HistoricalJobsController < Naf::ApplicationController
    include Naf::ApplicationHelper

    before_filter :set_cols_and_attributes
    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html
        format.json do
          set_page
          params[:search][:direction] = params['sSortDir_0']
          params[:search][:order] = Logical::Naf::Job::ORDER[params['iSortCol_0']]
          params[:search][:limit] = params['iDisplayLength']
          params[:search][:offset] = @page - 1
          @total_display_records = Logical::Naf::Job.total_display_records(params[:search])
          @total_records = Naf::HistoricalJob.count(:all)
          @historical_jobs = []
          job =[]
          Logical::Naf::Job.search(params[:search]).map(&:to_hash).map do |hash|
            add_urls(hash).map do |key, value|
              value ||= ''
              job << value
            end
            @historical_jobs << job
            job = []
          end
          render layout: 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      historical_job = Naf::HistoricalJob.find(params[:id])
      @historical_job = Logical::Naf::Job.new(historical_job)
      respond_to do |format|
        format.json do
          render json: { success: true }.to_json
        end
        format.html do
          render template: 'naf/record'
        end
      end
    end

    def new
    end

    def create
      @historical_job = Naf::HistoricalJob.new(params[:job])
      if params[:job][:application_id] && app = Naf::Application.find(params[:job][:application_id])
        if schedule = app.application_schedule
          @historical_job = Logical::Naf::JobCreator.new.queue_application_schedule(schedule)
        else
          @historical_job.command = app.command
          @historical_job.application_type_id = app.application_type_id
          @historical_job.application_run_group_restriction_id = Naf::ApplicationRunGroupRestriction.no_limit.id
        end
      end

      respond_to do |format|
        format.json do
          render json: { success: true,
                         title: @historical_job.title,
                         command: @historical_job.command }.to_json if @historical_job.save
        end

        format.html do
          if @historical_job.save
            redirect_to(@historical_job,
                        notice: "Job '#{@historical_job.command}' was successfully created.")
          else
            render action: "new"
          end
        end
      end
    end

    def edit
      @historical_job = Naf::HistoricalJob.find(params[:id])
    end

    def update
      respond_to do |format|
        @historical_job = Naf::HistoricalJob.find(params[:id])
        if @historical_job.update_attributes(params[:historical_job])
          format.html do
            redirect_to(@historical_job, notice: "Job '#{@historical_job.command}' was successfully updated.")
          end
          format.json do
            render json: { success: true,
                           title: @historical_job.title,
                           command: @historical_job.command }.to_json
          end
        else
          format.html do 
            render action: "edit"
          end
          format.json do
            render json: { success: false }.to_json
          end
        end
      end
    end

    private

    def set_cols_and_attributes
      @attributes = Logical::Naf::Job::ATTRIBUTES
    end

    def add_urls(hash)
      job = ::Naf::HistoricalJob.find(hash[:id])
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
