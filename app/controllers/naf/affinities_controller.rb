module Naf
  class AffinitiesController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::Affinity.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::Affinity.find(params[:id])
      render :template => 'naf/record'
    end
    
    private
    
    def set_cols_and_attributes
      @attributes = Naf::Affinity.attribute_names.map(&:to_s) << :affinity_classification_name
      @cols = [:affinity_name, :affinity_classification_name, :selectable]
    end

  end
end
