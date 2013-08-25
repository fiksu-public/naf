module Naf
  class MachineRunnerInvocationsController < Naf::ApplicationController

    def index
      if params[:machine_runner_id].present?
        @machine_runner_invocations = Naf::MachineRunnerInvocation.
          where(machine_runner_id: params[:machine_runner_id]).
          order('id DESC').all
      else
        @machine_runner_invocations = Naf::MachineRunnerInvocation.
          order('id DESC').all
      end
    end

    def show
      @machine_runner_invocation = Naf::MachineRunnerInvocation.find(params[:id])
    end

  end
end
