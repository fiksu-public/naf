module Logical
  module Naf
    class Application

      attr_reader :app

      include ActionView::Helpers::TextHelper

      COLUMNS = [:id,
                 :title,
                 :short_name,
                 :script_type_name,
                 :application_run_group_name,
                 :application_run_group_restriction_name,
                 :application_run_group_limit,
                 :enabled,
                 :enqueue_backlogs,
                 :run_time,
                 :affinities,
                 :prerequisites,
                 :deleted,
                 :visible]

      FILTER_FIELDS = [:deleted,
                       :enabled,
                       :visible]

      SEARCH_FIELDS = [:title,
                       :application_run_group_name,
                       :command,
                       :short_name]

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
            if field == :enabled || field == :visible
              application_scope.where(application_schedules: { field => search[field] })
            else
              application_scope.where(field => search[field])
            end
          end
        end

        SEARCH_FIELDS.each do |field|
          if search.present? and search[field].present?
            application_scope =
            if field == :application_run_group_name
              application_scope.where(
                ["lower(#{::Naf.schema_name}.application_schedules.application_run_group_name) ~ ?", Regexp.escape(search[field].downcase)]
              )
            else
              application_scope.where(["lower(#{field}) ~ ?", Regexp.escape(search[field].downcase)])
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

      def run_time
        run_time = run_interval
        run_time = "not scheduled" if run_time.blank?

        run_time
      end

      def run_interval
        output = ''
        if schedule = @app.application_schedule
          time = schedule.run_interval
          if schedule.run_interval_style.name == 'at beginning of day'
            output = exact_time_of_day(time)
          else
            output = interval_time(time)
          end
        end

        output
      end

      def exact_time_of_day(time)
        output = ""
        if schedule = @app.application_schedule
          minutes = schedule.run_interval % 60
          hours =   schedule.run_interval / 60
          output << hours.to_s + ":"
          output << "%02d" % minutes
          output = Time.parse(output).strftime("%I:%M %p")
        end

        return output
      end

      def interval_time(time)
        if time < 60
          pluralize(time, "minute")
        elsif time % 60 == 0
          pluralize(time / 60, "hour")
        else
          pluralize(time / 60, "hour") + ', ' + pluralize(time % 60, "minute")
        end
      end

      def prerequisites
        if schedule = @app.application_schedule && schedule.try(:application_schedule_prerequisites).present?
          schedule.prerequisites.map do |schedule_prerequisite|
            schedule_prerequisite.application.short_name_if_it_exist
          end.join(", \n")
        end
      end

      def application_run_group_name
        if schedule = @app.application_schedule
          if schedule.application_run_group_name.blank?
            "not set"
          else
            schedule.application_run_group_name
          end
        end
      end

      def method_missing(method_name, *arguments, &block)
        case method_name
        when :application_run_group_restriction_name,
             :application_run_group_name,
             :priority,
             :application_run_group_limit,
             :visible,
             :enabled
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

      def enqueue_backlogs
        application_schedule.try(:enqueue_backlogs)
      end

      def affinities
        if @app.application_schedule.try(:application_schedule_affinity_tabs).present?
          @app.application_schedule.application_schedule_affinity_tabs.map do |tab|
            if tab.affinity_short_name.present?
              if tab.affinity_parameter.present? && tab.affinity_parameter > 0
                tab.affinity_short_name + "(#{tab.affinity_parameter})"
              else
                tab.affinity_short_name
              end
            else
              tab.affinity_classification_name + '_' + tab.affinity_name
            end
          end.join(", \n")
        end
      end

    end
  end
end
