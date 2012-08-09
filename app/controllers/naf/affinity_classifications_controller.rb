module Naf
  class AffinityClassificationsController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::AffinityClassification.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::AffinityClassification.find(params[:id])
      render :template => 'naf/record'
    end
    
    private
    
    def set_cols_and_attributes
      @attributes = Naf::AffinityClassification.attribute_names.map(&:to_sym)
      @cols = [:affinity_classification_name]
    end

  end
end
