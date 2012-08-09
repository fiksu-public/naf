module Naf
  class ApplicationRunGroupsController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::ApplicationRunGroup.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::ApplicationRunGroup.find(params[:id])
      render :template => 'naf/record'
    end
    
    def destroy
      @run_group = Naf::ApplicationRunGroup.find(params[:id])
      @run_group.destroy
      redirect_to :action => 'index'
    end

    def new
      @run_group = Naf::ApplicationRunGroup.new
    end

    def create
     @run_group = Naf::ApplicationRunGroup.new(params[:application_run_group])
      if @run_group.save
        redirect_to(@run_group, :notice => 'Application Run Group  was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @run_group = Naf::ApplicationRunGroup.find(params[:id])
    end

    def update
      @run_group = Naf::ApplicationRunGroup.find(params[:id])
      if @run_group.update_attributes(params[:application_run_group])
        redirect_to(@run_group, :notice => 'Application Run Group was successfully updated.') 
      else
        render :action => "edit"
      end
    end


    private
    
    def set_cols_and_attributes
      @attributes = Naf::ApplicationRunGroup.attribute_names.map(&:to_sym)
      @cols = [:application_run_group_name]
    end

  end
end
