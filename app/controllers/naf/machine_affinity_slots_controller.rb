module Naf
  class MachineAffinitySlotsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
    
    def index
      @rows = Naf::MachineAffinitySlot.all
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::MachineAffinitySlot.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @slot = Naf::MachineAffinitySlot.find(params[:id])
      @slot.destroy
      redirect_to :action => 'index'
    end

    def new
      @slot = Naf::MachineAffinitySlot.new
    end

    def create
      @slot = Naf::MachineAffinitySlot.new(params[:machine_affinity_slot])
      if  @slot.save
        redirect_to(@slot, :notice => 'Machine Affinity Slot was successfully created.')
      else
        render :action => "new"
      end
    end

    def edit
      @slot = Naf::MachineAffinitySlot.find(params[:id])
    end

    def update
      @slot = Naf::MachineAffinitySlot.find(params[:id])
      if @slot.update_attributes(params[:machine_affinity_slot])
        redirect_to(@slot, :notice => 'Machine Affinity Slot was successfully updated.')
      else
        render :action => "edit"
      end
    end

    private 

    def set_cols_and_attributes
      @attributes = Naf::MachineAffinitySlot.attribute_names.map(&:to_sym)
      @cols = [:machine_server_name, :machine_server_address, :affinity_name, :affinity_classification_name, :required]
    end

  end
end
