module Logical
  module Naf
    class Application

      attr_reader :app
      
      include ActionView::Helpers::TextHelper

      COLUMNS = [:id, :title, :script_type_name, :application_run_group_name, :application_run_group_restriction_name, :run_start_minute, :run_interval, :deleted]

      def initialize(naf_app)
        @app = naf_app
      end
      
      def self.all
        ::Naf::Application.all.map{|a| new(a)}
      end
      
      def to_hash
        Hash[ COLUMNS.map{ |m| [m, send(m)] } ]
      end

      def command
        @app.command
      end
      
      def run_start_minute
        output = ""
        if schedule = @app.application_schedule and schedule.run_start_minute.present?
          minutes = schedule.run_start_minute % 60
          hours =   schedule.run_start_minute / 60
          output << hours.to_s + ":"
          output << "%02d" % minutes
          output = Time.parse(output).strftime("%I:%M %p")
        end

        return output
      end

      def method_missing(method_name, *arguments, &block)
        case method_name
        when :application_run_group_restriction_name, :run_interval, :application_run_group_name, :run_start_minute, :priority, :visible, :enabled
          if schedule = @app.application_schedule
            schedule.send(method_name, *arguments, &block)
          else
            nil
          end
        else
          if @app.respond_to?(method_name)
            @app.send(method_name, *arguments, &block)
          else
            super
          end
        end
      end
      
    end
  end
end
