module Logical
  module Naf
    class Application
      include ActionView::Helpers::TextHelper

      COLUMNS = [:title, :command, :script_type_name, :application_run_group_name, :application_run_group_restriction_name, :run_interval, :deleted]
      
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
        truncate(@app.command)
      end
      
      def method_missing(method_name, *arguments, &block)
        case method_name
        when :application_run_group_restriction_name, :run_interval, :application_run_group_name
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
