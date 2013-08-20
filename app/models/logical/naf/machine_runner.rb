# A wrapper around Naf::Machine
# used for rendering in views

module Logical
  module Naf
    class MachineRunner

      def self.to_array
        machine_runners = []
        ::Naf::MachineRunner.order('created_at DESC').all.each do |runner|
          values = []
          runner.attributes.each do |key, value|
            if key == 'created_at'
              values << value.to_s
            else
              values << value
            end
          end
          machine_runners << values
        end

        machine_runners
      end

    end
  end
end
