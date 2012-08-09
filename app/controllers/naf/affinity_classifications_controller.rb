module Naf
  class AffinityClassificationsController < ApplicationController

    before_filter :set_cols_and_attributes
  
    def index
      @rows = Naf::AffinityClassification.all
      render :template => 'naf/datatable'
    end
    
    def show
      @record = Naf::AffinityClassification.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @classification = Naf::AffinityClassification.find(params[:id])
      @classification.destroy
      redirect_to :action => 'index'
    end

    def new
      @classification = Naf::AffinityClassification.new
    end
    
    def create
      @classification = Naf::AffinityClassification.new(params[:affinity_classification])
      if  @classification.save
        redirect_to(@classification, :notice => 'Affinity Classification was successfully created.') 
      else
        render :action => "new"
      end
    end

    def edit
      @classification = Naf::AffinityClassification.find(params[:id])
    end

    def update
      @classification = Naf::AffinityClassification.find(params[:id])
      if @classification.update_attributes(params[:affinity_classification])
        redirect_to(@classification, :notice => 'Affinity Classification was successfully updated.') 
      else
        render :action => "edit"
      end
    end

    
    private
    
    def set_cols_and_attributes
      @attributes = Naf::AffinityClassification.attribute_names.map(&:to_sym)
      @cols = [:affinity_classification_name]
    end

  end
end
