module Naf
  class MachineAffinitySlotsController < ApplicationController

    before_filter :set_cols_and_attributes
    
    def index
      @rows = Naf::MachineAffinitySlot.all
      render :template => 'naf/datatable'
    end

    def show
      @slot = Naff::MachineAffinitySlot.find(params[:id])
    end

    private 

    def set_cols_and_attributes
      @attributes = Naf::MachineAffinitySlot.attribute_names.map(&:to_sym)
      @cols = [:machine_server_address, :affinity_name, :affinity_classification_name, :required]
    end

  end
end
