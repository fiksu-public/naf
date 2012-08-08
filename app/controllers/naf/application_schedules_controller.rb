module Naf
  class ApplicationSchedulesController < ApplicationController

    before_filter :set_cols
  
    def index
      @rows = Naf::ApplicationSchedule.all
      render :template => 'naf/datatable'
    end
    
    def show
      @application_schedule = Naf::ApplicationSchedule.find(params[:id])
    end
    
    private
    
    def set_cols
      @cols = Naf::ApplicationSchedule.attribute_names.map(&:to_sym)
    end

  end
end
