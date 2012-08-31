module Naf
  class MachinesController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @rows = Logical::Naf::Machine.all
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::Machine.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @machine = Naf::Machine.find(params[:id])
      @machine.destroy
      redirect_to machines_path
    end


    def new
      @machine = Naf::Machine.new
    end
    
    def create
      @machine = Naf::Machine.new(params[:machine])
      if @machine.save
        redirect_to(@machine, :notice => 'Machine was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @machine = Naf::Machine.find(params[:id])
    end

    def update
      @machine = Naf::Machine.find(params[:id])
      if @machine.update_attributes(params[:machine])
        redirect_to(@machine, :notice => 'Machine was successfully updated.') 
      else
        render :action => "edit"
      end
    end

    

    private

    def set_cols_and_attributes
      @attributes = Naf::Machine.attribute_names.map(&:to_sym)
      @cols = Logical::Naf::Machine::COLUMNS
    end

  end

  

end
