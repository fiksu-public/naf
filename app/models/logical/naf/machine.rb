# A wrapper around Naf::Machine
# used for rendering in views

module Logical
  module Naf
    class Machine
      
      include ActionView::Helpers::DateHelper
      
      COLUMNS = [:id, :server_name, :server_address, :server_note, :enabled, :process_pool_size, :last_checked_schedules_at, :last_seen_alive_at, :log_level, :affinities, :marked_down]
      
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
      
      def self.all
        ::Naf::Machine.all.map{|machine| new(machine)}
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
        Hash[ COLUMNS.map{|m| [m, send(m)]} ]
      end

      def affinities
        @machine.machine_affinity_slots.map do |slot|
          if slot.affinity_short_name
            slot.affinity_short_name
          else
            name = slot.affinity_classification_name + '_' + slot.affinity_name
            name = name + '_required' if slot.required
            name
          end
        end.join(", \n")
      end
      
    end
  end
end
