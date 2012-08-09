module Naf
  class MachinesController < ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @rows = Naf::Machine.all
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::Machine.find(params[:id])
      render :template => 'naf/record'
    end

    private

    def set_cols_and_attributes
      @attributes = Naf::Machine.attribute_names.map(&:to_sym)
      @cols = @attributes - [:id, :created_at, :updated_at]
    end

  end

  

end
