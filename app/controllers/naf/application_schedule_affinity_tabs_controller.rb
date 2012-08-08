module Naf
  class ApplicationScheduleAffinityTabsController < ApplicationController

    before_filter :set_cols
  
    def index
      @rows = Naf::ApplicationScheduleAffinityTab.all
      render :template => 'naf/datatable'
    end
    
    def show
      @tab = Naf::ApplicationScheduleAffinityTab.find(params[:id])
    end
    
    private
    
    def set_cols
      @cols = Naf::ApplicationScheduleAffinityTab.attribute_names.map(&:to_sym)
    end



  end
end
