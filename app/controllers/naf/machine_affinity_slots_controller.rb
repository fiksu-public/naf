module Naf
  class MachineAffinitySlotsController < ApplicationController

    before_filter :set_cols
    
    def index
      @rows = Naf::MachineAffinitySlot.all
      render :template => 'naf/datatable'
    end

    def show
      @slot = Naff::MachineAffinitySlot.find(params[:id])
    end

    private 

    def set_cols
      @cols = Naf::MachineAffinitySlot.attribute_names.map(&:to_sym)
    end

  end
end
