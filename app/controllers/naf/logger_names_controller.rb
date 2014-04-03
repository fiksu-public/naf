module Naf
  class LoggerNamesController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @rows = Naf::LoggerName.all
      render template: 'naf/datatable'
    end

    def show
      @logger_name = Naf::LoggerName.find(params[:id])
    end

    def destroy
      @logger_name = Naf::LoggerName.find(params[:id])
      @logger_name.destroy
      flash[:notice] = "Logger Name '#{@logger_name.name}' was successfully deleted."
      redirect_to(action: "index")
    end

    def new
      @logger_name = Naf::LoggerName.new
    end

    def create
      @logger_name = Naf::LoggerName.new(params[:logger_name])
      if @logger_name.save
        redirect_to(@logger_name,
                    notice: "Logger Name '#{@logger_name.name}' was successfully created.")
      else
        render action: "new"
      end
    end

    def edit
      @logger_name = Naf::LoggerName.find(params[:id])
    end

    def update
      @logger_name = Naf::LoggerName.find(params[:id])
      if @logger_name.update_attributes(params[:logger_name])
        redirect_to(@logger_name,
                    notice: "Logger Name '#{@logger_name.name}' was successfully updated.")
      else
        render action: "edit"
      end
    end

    private

    def set_cols_and_attributes
      @attributes = Naf::LoggerName.attribute_names.map(&:to_s)
      @cols = [:id, :name]
    end

  end
end
