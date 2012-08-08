module Naf
  class AffinitiesController < ApplicationController

    before_filter :set_cols
  
    def index
      @rows = Naf::Affinity.all
      render :template => 'naf/datatable'
    end
    
    def show
      @affinity = Naf::Affinity.find(params[:id])
    end
    
    private
    
    def set_cols
      @cols = Naf::Affinity.attribute_names.map(&:to_sym)
    end

  end
end
