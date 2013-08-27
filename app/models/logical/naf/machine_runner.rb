# A wrapper around Naf::MachineRunner used for rendering in views

module Logical
  module Naf
    class MachineRunner

      def self.to_array
        machine_runners = []
        ::Naf::MachineRunner.enabled.order('created_at DESC').all.each do |runner|
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
            where(machine_runner_id: runner.id).count
          values << ''

          machine_runners << values
        end

        machine_runners
      end

    end
  end
end
