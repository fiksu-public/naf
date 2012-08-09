module Naf
  class ApplicationSchedulesController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::ApplicationSchedule.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationSchedule.find(params[:id])
      render :template => 'naf/record'
    end
    
    private
    
    def set_cols_and_attributes
      @cols = [:title, :application_run_group_name, :application_run_group_restriction_name, :run_interval, :priority, :enabled, :visible]
      @attributes = Naf::ApplicationSchedule.attribute_names.map(&:to_sym) + @cols
    end

  end
end
