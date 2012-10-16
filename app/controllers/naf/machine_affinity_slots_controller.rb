module Naf
  class MachineAffinitySlotsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
    
    def index
      @rows = []
      if params[:machine_id]
        @rows = Naf::MachineAffinitySlot.where(:machine_id => params[:machine_id])
      end
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::MachineAffinitySlot.find(params[:id])
      @machine = Naf::Machine.find(params[:machine_id])
      render :template => 'naf/record'
    end

    def destroy
      @machine = Naf::Machine.find(params[:machine_id])
      @slot = Naf::MachineAffinitySlot.find(params[:id])
      @slot.destroy
      redirect_to machine_machine_affinity_slots_path(@machine)
    end

    def new
      @machine = Naf::Machine.find(params[:machine_id])
      @slot = Naf::MachineAffinitySlot.new
    end

    def create
      @machine = Naf::Machine.find(params[:machine_affinity_slot][:machine_id])
      @slot = Naf::MachineAffinitySlot.new(params[:machine_affinity_slot])
      if  @slot.save
        redirect_to(machine_machine_affinity_slot_path(@machine, @slot), :notice => 'Machine Affinity Slot was successfully created.') 
      else
        render :action => "new", :machine_id => @machine.id
      end
    end

    def edit
      @slot = Naf::MachineAffinitySlot.find(params[:id])
      @machine = Naf::Machine.find(params[:machine_id])
    end

    def update
      @slot = Naf::MachineAffinitySlot.find(params[:id])
      @machine = Naf::Machine.find(@slot.machine_id)
      if @slot.update_attributes(params[:machine_affinity_slot])
        redirect_to(machine_machine_affinity_slot_path(@machine, @slot), :notice => "Machine Affinity Slot was successfully updated")
      else
        render :action => "edit", :machine_id => @machine.id
      end
    end


    private 

    def set_cols_and_attributes
      @attributes = Naf::MachineAffinitySlot.attribute_names.map(&:to_sym)
      @cols = [:id, :machine_server_name, :machine_server_address, :affinity_name, :affinity_classification_name, :required]
    end

  end
end
