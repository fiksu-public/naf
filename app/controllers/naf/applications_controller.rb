module Naf
  class ApplicationsController < ApplicationController

    before_filter :set_cols

    def index
      @rows = Naf::Application.all
      render :template => 'naf/datatable'
    end

    def show
      @application = Naf::Application.find(params[:id])
    end

    private

    def set_cols
      @cols = Naf::Application.attribute_names.map(&:to_sym)
    end

  end

  

end
