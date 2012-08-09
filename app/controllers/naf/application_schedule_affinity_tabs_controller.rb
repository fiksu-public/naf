module Naf
  class ApplicationScheduleAffinityTabsController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::ApplicationScheduleAffinityTab.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationScheduleAffinityTab.find(params[:id])
      render :template => 'naf/record'
    end
    
    private
    
    def set_cols_and_attributes
      @cols = [:script_title, :affinity_name, :affinity_classification_name]
      @attributes = Naf::ApplicationScheduleAffinityTab.attribute_names.map(&:to_sym) + @cols
    end



  end
end
