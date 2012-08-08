module Naf
  class ApplicationRunGroupRestrictionsController < ApplicationController

    before_filter :set_cols
  
    def index
      @rows = Naf::ApplicationRunGroupRestriction.all
      render :template => 'naf/datatable'
    end
    
    def show
      @application_schedule = Naf::ApplicationRunGroupRestriction.find(params[:id])
    end
    
    private
    
    def set_cols
      @cols = Naf::ApplicationRunGroupRestriction.attribute_names.map(&:to_sym)
    end

  end
end
