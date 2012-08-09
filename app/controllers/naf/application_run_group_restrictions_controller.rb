module Naf
  class ApplicationRunGroupRestrictionsController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::ApplicationRunGroupRestriction.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationRunGroupRestriction.find(params[:id])
      render :template => 'naf/record'
    end


    private
    
    def set_cols_and_attributes
      @attributes = Naf::ApplicationRunGroupRestriction.attribute_names.map(&:to_sym)
      @cols = [:application_run_group_restriction_name]
    end

  end
end
