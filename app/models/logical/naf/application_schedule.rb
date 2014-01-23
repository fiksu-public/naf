module Logical
  module Naf
    class ApplicationSchedule

      attr_reader :schedule

      include ActionView::Helpers::TextHelper

      COLUMNS = [:id,
                 :application,
                 :application_run_group_name,
                 :application_run_group_restriction_name,
                 :run_interval_style,
                 :run_interval,
                 :application_run_group_quantum,
                 :application_run_group_limit,
                 :enqueue_backlogs,
                 :affinities,
                 :prerequisites,
                 :enabled,
                 :visible]

      # Mapping of datatable column positions and job attributes
      ORDER = { '0' => "id",
                '1' => "application_id",
                '2' => "application_run_group_name",
                '3' => "application_run_group_restriction_id",
                '4' => "run_interval_style_id",
                '5' => "run_interval",
                '6' => "application_run_group_quantum",
                '7' => "application_run_group_limit",
                '8' => "enqueue_backlogs" }

      def initialize(naf_schedule)
        @schedule = naf_schedule
      end

      def self.search(search)
        direction = search['sSortDir_0']
        order = ORDER[search['iSortCol_0']]
        ::Naf::ApplicationSchedule.
          order("#{order} #{direction}").
          all.map{ |physical_app_schedule| new(physical_app_schedule) }
      end

      def to_hash
        Hash[ COLUMNS.map{ |m| [m, send(m)] } ]
      end

      def run_interval_style
        schedule.run_interval_style.name
      end

      def affinities
        output = ''
        if schedule.try(:application_schedule_affinity_tabs).present?
          output = schedule.application_schedule_affinity_tabs.map do |tab|
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

        return output
      end

      def prerequisites
        if schedule.try(:application_schedule_prerequisites).present?
          schedule.prerequisites.map do |schedule_prerequisite|
            schedule_prerequisite.application.short_name_if_it_exist
          end.join(", \n")
        end
      end

      def display
        output = ''

        name = schedule.run_interval_style.name
        if name == 'at beginning of day'
          output << "daily(#{run_interval})"
        elsif name == 'at beginning of hour'
          output << "hourly(#{run_interval})"
        elsif name == 'after previous run'
          output << "run(#{run_interval})"
        elsif name == 'keep running'
          output << 'always'
        end

        if schedule.application_run_group_quantum == schedule.application_run_group_limit
          output << "-#{schedule.application_run_group_quantum}"
        else
          output << "-#{schedule.application_run_group_quantum}/#{schedule.application_run_group_limit}"
        end

        output
      end

      def help_title
        output = 'Run this application '

        name = schedule.run_interval_style.name
        if name == 'at beginning of day'
          output << "every day at #{run_interval}. "
        elsif name == 'at beginning of hour'
          output << "after #{schedule.run_interval} minute(s) of every hour. "
        elsif name == 'after previous run'
          output << "every #{schedule.run_interval} minute(s). "
        elsif name == 'keep running'
          output << 'constantly. '
        end

        output << "This schedule will queue #{schedule.application_run_group_quantum} job(s), and "
        output << "will not queue more than the group's limit of #{schedule.application_run_group_limit} job(s)."

        output
      end

      def run_interval
        output = ''
        time = schedule.run_interval
        if schedule.run_interval_style.name == 'at beginning of day'
          output = exact_time_of_day(time)
        else
          output = interval_time2(time)
        end

        output
      end

      def exact_time_of_day(time)
        output = ''
        minutes = schedule.run_interval % 60
        hours =   schedule.run_interval / 60
        output << hours.to_s + ':'
        output << '%02d' % minutes
        output = Time.parse(output).strftime('%I:%M %p')

        return output
      end

      def interval_time2(time)
        if time < 9
          ":0#{time}"
        else
          ":#{time}"
        end
      end

      def interval_time(time)
        if time < 60
          pluralize(time, 'minute')
        elsif time % 60 == 0
          pluralize(time / 60, 'hour')
        else
          pluralize(time / 60, 'hour') + ', ' + pluralize(time % 60, 'minute')
        end
      end

      def application_run_group_name
        if schedule.application_run_group_name.present?
          schedule.application_run_group_name
        else
          'not set'
        end
      end

      def method_missing(method_name, *arguments, &block)
        if @schedule.respond_to?(method_name)
          @schedule.send(method_name, *arguments, &block)
        else
          super
        end
      end

    end
  end
end
