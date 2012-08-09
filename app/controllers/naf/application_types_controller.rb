module Naf
  class ApplicationTypesController < ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @rows = Naf::ApplicationType.all
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::ApplicationType.find(params[:id])
      render :template => 'naf/record'
    end

    private

    def set_cols_and_attributes
      @attributes = Naf::ApplicationType.attribute_names.map(&:to_sym)
      @cols = [:script_type_name, :description, :enabled]
    end

  end

  

end
