module Naf
  class JanitorialAssignmentsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

    def index
      @params_name = params_name
      @rows =
      if params[:deleted].nil? || params[:deleted] == "false"
        janitorial_assignment_type.where(deleted: false).order("id desc")
      else
        janitorial_assignment_type.order("id desc")
      end
      respond_to do |format|
        format.js
        format.html
      end
    end

    def show
      @record = janitorial_assignment_type.find(params[:id])
      render template: 'naf/record'
    end

    def new
      @janitorial_assignment = janitorial_assignment_type.new
    end

    def create
      @janitorial_assignment = janitorial_assignment_type.new(params[params_name])
      if  @janitorial_assignment.save
        redirect_to(@janitorial_assignment,
                    notice: "#{@janitorial_assignment.type} '#{@janitorial_assignment.model_name}' was successfully created.")
      else
        render action: "new"
      end
    end

    def edit
      @janitorial_assignment = janitorial_assignment_type.find(params[:id])
    end

    def update
      @janitorial_assignment = janitorial_assignment_type.find(params[:id])
      if @janitorial_assignment.update_attributes(params[params_name])
        redirect_to(@janitorial_assignment,
                    notice: "#{@janitorial_assignment.type} '#{@janitorial_assignment.model_name}' was successfully updated.")
      else
        render action: "edit"
      end
    end


    private

    def set_cols_and_attributes
      @attributes = Naf::JanitorialAssignment.attribute_names.map(&:to_sym)
      @cols = [:id, :type, :enabled, :model_name, :assignment_order]
    end

    def janitorial_assignment_type
      params[:type].constantize
    end

    def params_name
      case params[:type]
        when /Create/
          :janitorial_create_assignment
        when /Archive/
          :janitorial_archive_assignment
        when /Drop/
          :janitorial_drop_assignment
      end
    end

  end
end
