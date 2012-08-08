module Naf
  class AffinityClassificationsController < ApplicationController

    before_filter :set_cols
  
    def index
      @rows = Naf::AffinityClassification.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::AffinityClassification.find(params[:id])
    end
    
    private
    
    def set_cols
      @cols = Naf::AffinityClassification.attribute_names.map(&:to_sym)
    end

  end
end
