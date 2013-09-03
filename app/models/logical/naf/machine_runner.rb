# A wrapper around Naf::MachineRunner used for rendering in views

module Logical
  module Naf
    class MachineRunner

      COLUMNS = [
        'id',
        'created_at',
        'server_name',
        'runner_cwd'
      ]

      def self.to_array(column, order)
        machine_runners = []
        order_by = COLUMNS[column].to_s + ' ' + order
        ::Naf::MachineRunner.enabled.order(order_by).all.each do |runner|
          values = []
          runner.attributes.each do |key, value|
            if key == 'created_at'
              values << value.to_s
            else
              values << value
            end
          end

          invocation = runner.machine_runner_invocations.last
          values << invocation.id
          values << invocation.pid
          values << invocation.status.gsub('-', ' ').split.map(&:capitalize).join(' ')

          values << ::Naf::HistoricalJob.
            joins('inner join naf.running_jobs nj on nj.id = naf.historical_jobs.id').
            joins(:machine_runner_invocation).
            where('naf.machine_runner_invocations.machine_runner_id = ?', runner.id).count
          values << ''

          machine_runners << values
        end

        machine_runners
      end

    end
  end
end
