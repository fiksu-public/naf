module Naf
  class HistoricalJobsController < Naf::ApplicationController
    include Naf::ApplicationHelper
    helper Naf::TimeHelper

    before_filter :set_rows_per_page
    before_filter :set_search_status

    def index
      respond_to do |format|
        format.html
        format.json do
          set_page
          set_status

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
      @historical_job = Naf::HistoricalJob.find(params[:id])
      @logical_job = Logical::Naf::Job.new(@historical_job)
    end

    def new
      @historical_job = Naf::HistoricalJob.new
    end

    # If there is an application id specified, then the controller enqueues that application
    def reenqueue
      job = Naf::HistoricalJob.find(params[:job_id].to_i)
      success = false
      if params[:app_id].present?
        app = Naf::Application.find(params[:app_id].to_i)
        title = app.title
        @historical_job = ::Logical::Naf::ConstructionZone::Boss.new.enqueue_application(
          app,
          job.application_run_group_restriction,
          job.application_run_group_name,
          job.application_run_group_limit,
          job.priority,
          job.job_affinities,
          job.prerequisites,
          false,
          job.application_schedule)
        if @historical_job.present?
          success = true
        end
      else
        title = job.command
        @historical_job = ::Logical::Naf::ConstructionZone::Boss.new.reenqueue(job)
        if @historical_job.present?
          success = true
        end
      end
      render json: { success: success, title: title }.to_json
    end

    def create
      @historical_job = Naf::HistoricalJob.new(params[:historical_job])
      if params[:historical_job][:application_id] &&
        app = Naf::Application.find(params[:historical_job][:application_id])

        if schedule = app.application_schedules.first
          @historical_job = ::Logical::Naf::ConstructionZone::Boss.new.enqueue_application_schedule(schedule)
          if @historical_job.blank?
            render json: {
              success: false,
              title: ::Naf::Application.find_by_id(params[:historical_job][:application_id]).title
            }.to_json

            return
          end
        else
          @historical_job.command = app.command
          @historical_job.application_type_id = app.application_type_id
          @historical_job.application_run_group_restriction_id =
            Naf::ApplicationRunGroupRestriction.no_limit.id
          @queued_job = ::Naf::QueuedJob.new
        end
      else
        @queued_job = ::Naf::QueuedJob.new
      end

      if @queued_job.present?
        @queued_job.application_type_id = @historical_job.application_type_id
        @queued_job.command = @historical_job.command
        @queued_job.application_run_group_restriction_id =
          @historical_job.application_run_group_restriction_id
        @queued_job.application_run_group_name = @historical_job.application_run_group_name
        @queued_job.application_run_group_limit = @historical_job.application_run_group_limit
        @queued_job.priority = @historical_job.priority
      end

      respond_to do |format|
        format.json do
          if @historical_job.save
            if @queued_job.present?
              @queued_job.id = @historical_job.id
              @queued_job.save
            end

            render json: { success: true,
                           title: @historical_job.title,
                           command: @historical_job.command }.to_json
          end
        end

        format.html do
          if @historical_job.save
            if @queued_job.present?
              @queued_job.id = @historical_job.id
              @queued_job.save
            end

            redirect_to(@historical_job,
                        notice: "Job '#{@historical_job.command}' was successfully created.")
          else
            render action: "new"
          end
        end
      end
    end

    def update
      respond_to do |format|
        @historical_job = Naf::HistoricalJob.find(params[:id])
        if @historical_job.update_attributes(params[:historical_job])

          ::Naf::HistoricalJob.lock_for_job_queue do
            if params[:historical_job][:request_to_terminate].present?
              if queued_job = ::Naf::QueuedJob.find_by_id(params[:id])
                @historical_job.finished_at = Time.zone.now
                @historical_job.save!
                queued_job.delete
              end

              if running_job = ::Naf::RunningJob.find_by_id(params[:id])
                running_job.update_attributes(request_to_terminate: true)
                @historical_job.update_attributes(request_to_terminate: true)
              end
            end

            format.html do
              redirect_to(
                @historical_job,
                notice: "Job '#{@historical_job.command}' was successfully updated."
              )
            end
            format.json do
              render json: { success: true,
                             title: @historical_job.title,
                             command: @historical_job.command }.to_json
            end
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

    def add_urls(hash)
      job = ::Naf::HistoricalJob.find(hash[:id])
      if application = job.application
        hash[:application_url] = url_for(application)
      else
        hash[:application_url] = nil
      end

      return hash
    end

  end
end
