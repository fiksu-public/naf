# A wrapper around Naf::MachineRunnerInvocation used for rendering in views

module Logical
  module Naf
    class MachineRunnerInvocation

      COLUMNS = [
        'id',
        'created_at',
        'machine_runner_id',
        'server_name',
        'pid',
        'status',
        'commit_information',
        'deployment_tag',
        'repository_name'
      ]

      def self.to_array(column, order, filter)
        machine_runner_invocations = []
        order_by = COLUMNS[column].to_s + ' ' + order

        if order_by =~ /status/
          order_by = "is_running #{order}, wind_down_at #{order}"
        end

        ::Naf::MachineRunnerInvocation.joins(machine_runner: :machine).choose(filter).order(order_by).all.each do |invocation|
          values = []
          invocation_hash = invocation.attributes
          COLUMNS.each do |key|
            if key == 'created_at'
              values << invocation_hash[key].to_s
            elsif key == 'server_name'
              machine_runner = ::Naf::MachineRunner.find_by_id(invocation_hash['machine_runner_id'])
              values << [machine_runner.machine.id, ::Logical::Naf::Machine.new(machine_runner.machine).name.to_s]
            elsif key == 'status'
              values << invocation.status.gsub('-', ' ').split.map(&:capitalize).join(' ')
            else
              values << invocation_hash[key]
            end
          end
          machine_runner_invocations << values
        end

        machine_runner_invocations
      end

    end
  end
end
