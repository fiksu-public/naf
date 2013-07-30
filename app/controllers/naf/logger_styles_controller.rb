module Naf
  class LoggerStylesController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @rows = Naf::LoggerStyle.all
      render :template => 'naf/datatable'
    end

    def show
      @logger_style = Naf::LoggerStyle.find(params[:id])
    end

    def destroy
      @logger_style = Naf::LoggerStyle.find(params[:id])
      @logger_style.destroy
      flash[:notice] = "Logger Style '#{@logger_style.name}' was successfully deleted."
      redirect_to(:action => "index")
    end

    def new
      @logger_style = Naf::LoggerStyle.new
      @logger_style.logger_style_names.build
    end

    def create
      @logger_style = Naf::LoggerStyle.new(params[:logger_style])
      if @logger_style.save
        redirect_to(@logger_style, :notice => "Logger Style '#{@logger_style.name}' was successfully created.")
      else
        render :action => "new"
      end
    end

    def edit
      @logger_style = Naf::LoggerStyle.find(params[:id])
    end

    def update
      @logger_style = Naf::LoggerStyle.find(params[:id])
      if @logger_style.update_attributes(params[:logger_style])
        redirect_to(@logger_style, :notice => "Logger Style '#{@logger_style.name}' was successfully updated.")
      else
        render :action => "edit"
      end
    end

    private

    def set_cols_and_attributes
      @attributes = Naf::LoggerStyle.attribute_names.map(&:to_sym)
      @cols = [:id, :name, :note, :_logger_names, :logger_levels]
    end

  end
end