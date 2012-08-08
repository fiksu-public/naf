module Naf
  class ApplicationRunGroupsController < ApplicationController

    before_filter :set_cols
  
    def index
      @rows = Naf::ApplicationRunGroup.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationRunGroup.find(params[:id])
    end
    
    private
    
    def set_cols
      @cols = Naf::ApplicationRunGroup.attribute_names.map(&:to_sym)
    end

  end
end
