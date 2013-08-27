# A wrapper around Naf::MachineRunnerInvocation used for rendering in views

module Logical
  module Naf
    class MachineRunnerInvocation

      COLUMNS = [
        :id,
        :created_at,
        :machine_runner_id,
        :pid,
        :is_running,
        :wind_down,
        :deployment_tag
      ]

      NOT_DISPLAYED = [
        'updated_at',
        'commit_information',
        'branch_name',
        'repository_name'
      ]

      def self.to_array(column, order, filter)
        machine_runner_invocations = []
        order_by = COLUMNS[column].to_s + ' ' + order
        ::Naf::MachineRunnerInvocation.choose(filter).order(order_by).all.each do |invocation|
          values = []
          invocation.attributes.each do |key, value|
            if key == 'created_at'
              values << value.to_s
            elsif !NOT_DISPLAYED.include?(key)
              values << value
            end
          end
          machine_runner_invocations << values
        end

        machine_runner_invocations
      end

    end
  end
end
