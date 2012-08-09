module Naf
  class ApplicationRunGroupsController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::ApplicationRunGroup.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationRunGroup.find(params[:id])
      render :template => 'naf/record'
    end
    
    private
    
    def set_cols_and_attributes
      @attributes = Naf::ApplicationRunGroup.attribute_names.map(&:to_sym)
      @cols = [:application_run_group_name]
    end

  end
end
