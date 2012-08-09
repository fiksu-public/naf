module Naf
  class ApplicationsController < ApplicationController

    before_filter :set_cols_and_attributes

 
    def index
      @rows = Naf::Application.all
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::Application.find(params[:id])
      render :template => 'naf/record'
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

    private

    def set_cols_and_attributes
      more_attributes = [:script_type_name]
      @attributes = Naf::Application.attribute_names.map(&:to_sym) + more_attributes
      @cols = [:title, :command, :script_type_name, :deleted]
    end

  end

  

end
