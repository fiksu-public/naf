module Logical
  module Naf
    class Application

      attr_reader :app
      
      include ActionView::Helpers::TextHelper

      COLUMNS = [:id, :title, :script_type_name, :application_run_group_name, :application_run_group_restriction_name, :run_time]

      FILTER_FIELDS = [:deleted, :enabled]

      SEARCH_FIELDS = [:title, :application_run_group_name, :command, :short_name]

      def initialize(naf_app)
        @app = naf_app
      end
      
      def self.search(search)
        application_scope = ::Naf::Application.
          joins("LEFT JOIN #{::Naf.schema_name}.application_schedules ON #{::Naf.schema_name}.application_schedules.application_id = #{::Naf.schema_name}.applications.id").
            order("id desc")
        FILTER_FIELDS.each do |field|
          if search.present? and search[field].present?
            application_scope =
            if field == :enabled
              application_scope.where(:application_schedules => { field => search[field] })
            else
              application_scope.where(field => search[field])
            end
          end
        end
        SEARCH_FIELDS.each do |field|
          if search.present? and search[field].present?
            application_scope =
            if field == :application_run_group_name
              application_scope.where(["lower(naf.application_schedules.application_run_group_name) ~ ?", search[field].downcase])
            else
              application_scope.where(["lower(#{field}) ~ ?", search[field].downcase])
            end
          end
        end

        application_scope.map{ |physical_app| new(physical_app) }
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

      def run_time
        run_time = run_start_minute.blank? ? run_interval : run_start_minute
        run_time = "not scheduled" if run_time.blank?

        run_time
      end

      def run_interval
        output = ""
        if schedule = @app.application_schedule and schedule.run_interval.present?
          time = schedule.run_interval
          output =
          if time == 0
            "run constantly"
          elsif time < 60
            pluralize(time, "minute")
          elsif time % 60 == 0
            pluralize(time / 60, "hour")
          else
            pluralize(time / 60, "hour") + ', ' + pluralize(time % 60, "minute")
          end
        end

        output
      end

      def method_missing(method_name, *arguments, &block)
        case method_name
        when :application_run_group_restriction_name, :run_interval, :application_run_group_name, :run_start_minute, :priority, :application_run_group_limit, :visible, :enabled
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
