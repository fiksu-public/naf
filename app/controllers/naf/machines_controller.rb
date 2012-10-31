module Naf
  class MachinesController < Naf::ApplicationController

    before_filter :set_cols_and_attributes
    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html do
        end
        format.json do
          set_page
          machines = []
          machine = []
          @total_records = Naf::Machine.count(:all)
          Logical::Naf::Machine.all.map(&:to_hash).map do |hash|
            hash.map do |key, value|
              value = '' if value.nil?
              machine << value
            end
            machines << machine
            machine =[]
          end
          @machines = machines.paginate(:page => @page, :per_page => @rows_per_page)
          render :layout => 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @record = Naf::Machine.find(params[:id])
      render :template => 'naf/record'
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
