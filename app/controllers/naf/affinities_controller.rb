module Naf
  class AffinitiesController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @rows = Naf::Affinity.all
      render template: 'naf/datatable'
    end

    def show
      @affinity = Naf::Affinity.find(params[:id])
    end

    def destroy
      @affinity = Naf::Affinity.find(params[:id])
      @affinity.destroy
      flash[:notice] = "Affinity '#{@affinity.affinity_name}' was successfully deleted."
      redirect_to(action: "index")
    end

    def new
      @affinity = Naf::Affinity.new
    end

    def create
      @affinity = Naf::Affinity.new(params[:affinity])
      if  @affinity.save
        redirect_to(@affinity, notice: "Affinity '#{@affinity.affinity_name}' was successfully created.")
      else
        render action: "new"
      end
    end

    def edit
      @affinity = Naf::Affinity.find(params[:id])
    end

    def update
      @affinity = Naf::Affinity.find(params[:id])
      if @affinity.update_attributes(params[:affinity])
        redirect_to(@affinity, notice: "Affinity '#{@affinity.affinity_name}' was successfully updated.")
      else
        render action: "edit"
      end
    end

    private

    def set_cols_and_attributes
      @cols = [:id, :affinity_classification_name, :affinity_name, :affinity_note]
    end

  end
end
