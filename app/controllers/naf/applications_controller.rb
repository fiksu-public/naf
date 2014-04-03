module Naf
  class ApplicationsController < Naf::ApplicationController

    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html
        format.json do
          set_page

          applications = []
          application = []
          params[:search][:deleted] = params[:search][:deleted] ? false : 'false'
          @total_records = Naf::Application.count(:all)
          Logical::Naf::Application.search(params[:search]).map(&:to_hash).map do |hash|
            hash.map do |key, value|
              value = '' if value.nil?
              application << value
            end
            applications << application
            application = []
          end
          @total_display_records = applications.count
          @applications = applications.paginate(page: @page, per_page: @rows_per_page)

          render layout: 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @application = Naf::Application.find(params[:id])
      @logical_application = Logical::Naf::Application.new(@application)
    end

    def new
      @application = Naf::Application.new
    end

    def create
      @application = Naf::Application.new(params[:application])
      if @application.save
        redirect_to(@application, notice: "Application #{@application.title} was successfully created.")
      else
        render action: :new
      end
    end

    def edit
      @application = Naf::Application.find(params[:id])
    end

    def update
      @application = Naf::Application.find(params[:id])
      if @application.update_attributes(params[:application])
        redirect_to(@application, notice: "Application #{@application.title} was successfully updated.")
      else
        render action: :edit
      end
    end

  end
end
