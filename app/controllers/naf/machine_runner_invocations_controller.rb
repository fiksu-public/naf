module Naf
  class MachineRunnerInvocationsController < Naf::ApplicationController

    before_filter :set_rows_per_page

    def index
      respond_to do |format|
        format.html
        format.json do
          set_page

          @total_records = ::Naf::MachineRunnerInvocation.count(:all)
          @rows = ::Logical::Naf::MachineRunnerInvocation.
            to_array(params['iSortCol_0'].to_i, params['sSortDir_0'], params['filter']['invocations']).
            paginate(page: @page, per_page: @rows_per_page)

          render layout: 'naf/layouts/jquery_datatables'
        end
      end
    end

    def show
      @machine_runner_invocation = Naf::MachineRunnerInvocation.find(params[:id])
    end

    def update
      respond_to do |format|
        @machine_runner_invocation = Naf::MachineRunnerInvocation.find(params[:id])
        format.json do
          if params[:machine_runner_invocation][:request_to_wind_down].present?
            @machine_runner_invocation.update_attributes!(wind_down: true)
            @machine_runner_invocation.machine_runner.reload
            render json: { success: true }.to_json
          else
            render json: { success: false }.to_json
          end
        end
      end
    end

  end
end
