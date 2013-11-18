module Naf
  class HistoricalJobAffinityTabsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @rows = []
      if params[:historical_job_id]
        @rows = Naf::HistoricalJobAffinityTab.where(historical_job_id: params[:historical_job_id])
      end
      render template: 'naf/datatable'
    end

    def show
      @record = Naf::HistoricalJobAffinityTab.find(params[:id])
      @job =    Naf::HistoricalJob.find(params[:historical_job_id])
      render template: 'naf/record'
    end

    def new
      @job = Naf::HistoricalJob.find(params[:historical_job_id])
      @tab = Naf::HistoricalJobAffinityTab.new

      if @job.present? && @job.finished_at.present?
        flash[:error] = "Can't add an affinity tab to a finished job!"
        redirect_to :back
      end
    end

    def create
      @job = Naf::HistoricalJob.find(params[:historical_job_id])
      @tab = Naf::HistoricalJobAffinityTab.new(params[:historical_job_affinity_tab])
      if @tab.save
        redirect_to(naf.historical_job_historical_job_affinity_tab_path(@job, @tab),
                    notice: "Historical Job Affinity Tab '#{@tab.affinity_name}' was successfully created.")
      else
        render action: "new", historical_job_id: @job.id
      end
    end

    def edit
      @job = Naf::HistoricalJob.find(params[:historical_job_id])
      @tab = Naf::HistoricalJobAffinityTab.find(params[:id])
    end

    def update
      @job = Naf::HistoricalJob.find(params[:historical_job_id])
      @tab = Naf::HistoricalJobAffinityTab.find(params[:id])
      if @tab.update_attributes(params[:historical_job_affinity_tab])
        redirect_to(naf.historical_job_historical_job_affinity_tab_path(@job, @tab),
                    notice: "Historical Job Affinity Tab '#{@tab.affinity_name}' was successfully updated.")
      else
        render action: "edit", historical_job_id: @job.id
      end
    end

    private

    def set_cols_and_attributes
      @cols = [:id, :script_type_name, :command, :affinity_classification_name, :affinity_name]
      @attributes = Naf::HistoricalJobAffinityTab.attribute_names.map(&:to_sym) | @cols  << :affinity_short_name
    end

  end
end
