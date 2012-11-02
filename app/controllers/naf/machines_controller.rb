module Naf
  class MachinesController < Naf::ApplicationController

    include Naf::ApplicationHelper

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
            add_urls(hash).map do |key, value|
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
        redirect_to(@machine, :notice => "Machine '#{@machine.server_name.blank? ? @machine.server_address : @machine.server_name}' was successfully created.")
      else
        render :action => "new"
      end
    end

    def edit
      @machine = Naf::Machine.find(params[:id])
    end

    def update
      respond_to do |format|
        @machine = Naf::Machine.find(params[:id])
        if params[:terminate]
          @machine.mark_machine_down(::Naf::Machine.local_machine)
          format.json do
            render :json => {:success => true}.to_json
          end
        end
        if @machine.update_attributes(params[:machine])
          format.html do
            redirect_to(@machine, :notice => "Machine '#{@machine.server_name.blank? ? @machine.server_address : @machine.server_name}' was successfully updated.")
          end
        else
          format.html do
            render :action => "edit"
          end
        end
      end
    end


    private

    def set_cols_and_attributes
      @attributes = Naf::Machine.attribute_names.map(&:to_sym)
    end

    def add_urls(hash)
      machine = ::Naf::Machine.find(hash[:id])
      hash[:papertrail_url] = papertrail_link(machine)
      hash[:papertrail_runner_url] = papertrail_link(machine, true)

      hash
    end

  end

end
