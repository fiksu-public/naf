module Naf
  class MachinesController < ApplicationController

    before_filter :set_cols

    def index
      @rows = Naf::Machine.all
      render :template => 'naf/datatable'
    end

    def show
      @machine = Naf::Machine.find(params[:id])
    end

    private

    def set_cols
      @cols = Naf::Machine.attribute_names.map(&:to_sym)
    end

  end

  

end
