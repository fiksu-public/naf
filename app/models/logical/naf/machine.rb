# A wrapper around Naf::Machine used for rendering in views

module Logical
  module Naf
    class Machine

      include ActionView::Helpers::DateHelper

      COLUMNS = [:id,
                 :server_name,
                 :server_address,
                 :server_note,
                 :enabled,
                 :process_pool_size,
                 :last_checked_schedules_at,
                 :last_seen_alive_at,
                 :log_level,
                 :affinities,
                 :marked_down]

      def initialize(naf_machine)
        @machine = naf_machine
      end

      def method_missing(method_name, *arguments, &block)
        if @machine.respond_to?(method_name)
          @machine.send(method_name, *arguments, &block)
        else
          super
        end
      end

      def self.all(filter = false)
        ::Naf::Machine.include_deleted(filter).to_a.map{ |machine| new(machine) }
      end

      def process_pool_size
        thread_pool_size
      end

      def last_checked_schedules_at
        if value = @machine.last_checked_schedules_at
          "#{time_ago_in_words(value, true)} ago, #{value.localtime.strftime("%Y-%m-%d %r")}"
        else
          ""
        end
      end

      def last_seen_alive_at
        if value = @machine.last_seen_alive_at
          "#{time_ago_in_words(value, true)} ago, #{value.localtime.strftime("%Y-%m-%d %r")}"
        else
          ""
        end
      end

      def to_hash
        Hash[COLUMNS.map{ |m| [m, send(m)] }]
      end

      def affinities
        @machine.machine_affinity_slots.map do |slot|
          if slot.affinity_short_name
            if slot.affinity_parameter.present? && slot.affinity_parameter > 0
              slot.affinity_short_name + "(#{slot.affinity_parameter})"
            else
              slot.affinity_short_name
            end
          else
            name = slot.affinity_classification_name + '_' + slot.affinity_name
            name = name + '_required' if slot.required
            name
          end
        end.join(", \n")
      end

      def name
        if @machine.short_name
          @machine.short_name
        elsif @machine.server_name
          @machine.server_name
        else
          @machine.server_address
        end
      end

      def status
        runner_down = true
        @machine.machine_runners.each do |runner|
          if runner.machine_runner_invocations.where(wind_down_at: nil, dead_at: nil).count > 0
            runner_down = false
            break;
          end
        end

        status = 'Good'
        if runner_down
          notes = 'Runner down'
          status = 'Bad'
        else
          notes = ''
        end

        { server_name: name,
          status: status,
          notes: notes }
      end

      def runner
        if @machine.server_name.present?
          @machine.server_name.to_s
        else
          if Rails.env == 'development'
            "localhost:#{Rails::Server.new.options[:Port]}"
          else
            @machine.server_address
          end
        end
      end

    end
  end
end
