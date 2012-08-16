module Naf
  class ApplicationsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

 
    def index
      @rows = Naf::Application.all
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::Application.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @application = Naf::Application.find(params[:id])
      @application.destroy
      redirect_to :action => 'index'
    end

    def new
      @application = Naf::Application.new
    end

    def create
     @application = Naf::Application.new(params[:application])
      if @application.save
        redirect_to(@application, :notice => 'Application was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @application = Naf::Application.find(params[:id])
    end

    def update
      @application = Naf::Application.find(params[:id])
      if @application.update_attributes(params[:application])
        redirect_to(@application, :notice => 'Application was successfully updated.') 
      else
        render :action => "edit"
      end
    end


    private

    def set_cols_and_attributes
      more_attributes = [:script_type_name]
      @attributes = Naf::Application.attribute_names.map(&:to_sym) | more_attributes
      @cols = [:title, :command, :script_type_name, :deleted]
    end

  end

  

end
