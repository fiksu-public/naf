module Naf
  class JobsController < Naf::ApplicationController

    before_filter :set_cols_and_attributes

 
    def index
      @rows = Naf::Job.all
      render :template => 'naf/datatable'
    end

    def show
      @record = Naf::Job.find(params[:id])
      render :template => 'naf/record'
    end

    def destroy
      @job = Naf::Job.find(params[:id])
      @job.destroy
      redirect_to :action => 'index'
    end

    def create
     @job = Naf::Job.new(params[:job])
     
      respond_to do |format|
        format.json do
          response = {:title => Naf::Application.find(params[:job][:application_id]).title}
          if @job.save
            response[:msg] = "Saved"
          else
            response[:msg] = "Not Saved"
          end
          render :json => response.to_json
        end
      end

#     render :nothing => true
#      if @job.save
#        redirect_to(@job, :notice => 'Job was successfully created.') 
#      else
#        render :action => "new"
#      end
    end

    def edit
      @job = Naf::Job.find(params[:id])
    end

    def update
      @job = Naf::Job.find(params[:id])
      if @job.update_attributes(params[:job])
        redirect_to(@job, :notice => 'Job was successfully updated.') 
      else
        render :action => "edit"
      end
    end


    private

    def set_cols_and_attributes
      more_attributes = [:title, :command, :script_type_name, :machine_started_on_server_address, :machine_started_on_server_name, :application_run_group_restriction_name]
      @attributes = Naf::Job.attribute_names.map(&:to_sym) + more_attributes
      @cols = [:title, :command, :script_type_name, :application_run_group_name, :application_run_group_restriction_name, :priority, :failed_to_start, :started_at, :finished_at, :pid, :exit_status, :request_to_terminate, :termination_signal, :machine_started_on_server_name, :machine_started_on_server_address]
    end

  end

  

end
