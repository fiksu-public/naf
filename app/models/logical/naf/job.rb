# A wrapper around Naf::HistoricalJob used for rendering in views

module Logical
  module Naf
    class Job
      include ActionView::Helpers::DateHelper
      include ActionView::Helpers::TextHelper

      COLUMNS = [:id,
                 :server,
                 :pid,
                 :queued_time,
                 :title,
                 :started_at,
                 :finished_at,
                 :run_time,
                 :affinities,
                 :tags,
                 :status]

      ATTRIBUTES = [:title,
                    :id,
                    :status,
                    :server,
                    :pid,
                    :queued_time,
                    :command,
                    :started_at,
                    :finished_at,
                    :run_time,
                    :exit_status,
                    :script_type_name,
                    :log_level,
                    :request_to_terminate,
                    :machine_started_on_server_address,
                    :machine_started_on_server_name,
                    :application_run_group_name,
                    :application_run_group_limit,
                    :application_run_group_restriction_name]

      FILTER_FIELDS = [:application_type_id,
                       :application_run_group_restriction_id,
                       :priority,
                       :failed_to_start,
                       :pid,
                       :exit_status,
                       :request_to_terminate,
                       :started_on_machine_id]

      SEARCH_FIELDS = [:command, :application_run_group_name]

      # Mapping of datatable column positions and job attributes
      ORDER = { '0' => "id",
                '2' => "pid",
                '3' => "created_at",
                '5' => "started_at",
                '6' => "finished_at",
                '10' => "status" }

      def initialize(naf_job)
        @job = naf_job
      end

      def method_missing(method_name, *arguments, &block)
        if @job.respond_to?(method_name)
          @job.send(method_name, *arguments, &block)
        else
          super
        end
      end

      def status
        if @job.request_to_terminate && @job.finished_at.nil?
          "Terminating"
        elsif @job.request_to_terminate && @job.finished_at.present?
          "Terminated"
        elsif @job.started_at and (not @job.finished_at)
          "Running"
        elsif (not @job.started_at) and (not @job.finished_at) and @job.failed_to_start
          "Failed to Start"
        elsif @job.exit_status and @job.exit_status > 0
          "Error #{@job.exit_status}"
        elsif @job.started_at and @job.finished_at
          "Finished"
        elsif @job.termination_signal
          "Signaled #{@job.termination_signal}"
        elsif @job.prerequisites.select { |pre| pre.started_at.nil? }.size > 0
          "Waiting"
        else
          "Queued"
        end
      end

      def title
        if application
          application.title
        else
          command
        end
      end

      def application_run_group_name
        if @job.application_run_group_name.blank?
          "not set"
        elsif @job.application_run_group_name == @job.command
          "command"
        else
          @job.application_run_group_name
        end
      end

      def server
        if started_on_machine
          name = started_on_machine.short_name_if_it_exist
          if name.blank?
            started_on_machine.server_address
          else
            name
          end
        end
      end

      # Given search, a hash of the search query for jobs on the queue,
      # build up and return the ActiveRecord scope
      #
      # We eventually build up these results over created_at/1.week partitions.
      def self.search(search)
        if search[:order] == "status"
          conditions = ""
          values = {}
          values[:limit] = search[:limit].to_i
          values[:offset]= search[:offset].to_i*search[:limit].to_i
          FILTER_FIELDS.each do |field|
            if search[field].present?
              conditions << " AND "
              case field
                when :failed_to_start, :request_to_terminate
                  values[field.to_sym] = search[field]
                  conditions << "#{field} = :#{field}"
                else
                  values[field.to_sym] = search[field].to_i
                  conditions << "#{field} = :#{field}"
              end
            end
          end
          SEARCH_FIELDS.each do |field|
            if search[field].present?
              conditions << " AND "
              conditions << "lower(#{field}) ~ :#{field}"
              values[field.to_sym] = search[field].downcase
            end
          end

          status = search[:status].blank? ? :all : search[:status]
          sql =
          case status.to_sym
            when :queued
              JobStatuses::Running.all(:queued, conditions) + "union all\n" +
              JobStatuses::Queued.all(conditions) + "union all\n" +
              JobStatuses::Waiting.all(conditions) + "union all\n" +
              JobStatuses::FinishedLessMinute.all(conditions) + "union all\n" +
              JobStatuses::Terminated.all(conditions)
            when :running
              JobStatuses::Running.all(conditions) + "union all\n" +
              JobStatuses::FinishedLessMinute.all(conditions) + "union all\n" +
              JobStatuses::Terminated.all(conditions)
            when :waiting
              JobStatuses::Waiting.all(conditions)
            when :finished
              JobStatuses::Finished.all(conditions)
            when :errored
              JobStatuses::Errored.all(conditions)
            else
              JobStatuses::Running.all(:queued, conditions) + "union all\n" +
              JobStatuses::Queued.all(conditions) + "union all\n" +
              JobStatuses::Waiting.all(conditions) + "union all\n" +
              JobStatuses::Finished.all(conditions) + "union all\n" +
              JobStatuses::Terminated.all(conditions)
          end
          sql << "LIMIT :limit OFFSET :offset"
          jobs = ::Naf::HistoricalJob.find_by_sql([sql, values]).uniq

          jobs.map{ |physical_job| new(physical_job) }
        else
          job_scope = self.get_job_scope(search)
          order, direction = search[:order], search[:direction]
          job_scope = job_scope.order("#{order} #{direction}").limit(search[:limit]).offset(search[:offset].to_i*search[:limit].to_i)

          if search[:status] == 'waiting'
            job_scope = job_scope.select{|job| job.prerequisites.select{ |pre| pre.started_at.nil? }.size > 0 }
          end

          job_scope.map{|physical_job| new(physical_job) }
        end
      end

      def self.total_display_records(search)
        job_scope = self.get_job_scope(search)

        if search[:status] == 'waiting'
          job_scope = job_scope.select{ |job| job.prerequisites.select{ |pre| pre.started_at.nil? }.size > 0 }
        end

        job_scope.count
      end

      def self.get_job_scope(search)
        status = search[:status].blank? ? :all : search[:status]
        case status.to_sym
          when :queued
            job_scope = ::Naf::HistoricalJob.queued_status
          when :running
            job_scope = ::Naf::HistoricalJob.running_status
          when :waiting
            job_scope = ::Naf::HistoricalJob.queued_with_waiting
          when :finished
            job_scope = ::Naf::HistoricalJob.finished
          when :errored
            job_scope = ::Naf::HistoricalJob.errored
          else
            job_scope = ::Naf::HistoricalJob.scoped
        end

        FILTER_FIELDS.each do |field|
          job_scope = job_scope.where(field => search[field]) if search[field].present?
        end
        SEARCH_FIELDS.each do |field|
          job_scope = job_scope.where(["lower(#{field}) ~ ?", search[field].downcase]) if search[field].present?
        end

        job_scope
      end

      def self.find(id)
        physical_job = ::Naf::HistoricalJob.find(id)
        physical_job ? new(physical_job) : nil
      end

      def application_url
        if application = @job.application
          return Rails.application.routes.url_helpers.application_path(application)
        else
          return nil
        end
      end

      def to_detailed_hash
        Hash[ ATTRIBUTES.map{ |m|
          case m
          when :started_at, :finished_at
            if value = @job.send(m)
              [m, value.localtime.strftime("%Y-%m-%d %r")]
            else
              [m, '']
            end
          else
            [m, send(m)]
          end
        }]
      end

      # Format the hash of a job record nicely for the table
      def to_hash
        Hash[ COLUMNS.map{ |m| [m, send(m)] } ]
      end

      def started_at
        if @job.started_at.present?
          value = Time.zone.now - @job.started_at
          if value < 60
            "#{value.to_i} seconds ago, #{@job.started_at.localtime.strftime("%Y-%m-%d %r")}"
          elsif value < 172_800
            time_difference(value)
          elsif value >= 172_800
            "#{time_ago_in_words(@job.started_at, true)} ago, #{@job.started_at.localtime.strftime("%Y-%m-%d %r")}"
          else
            ""
          end
        else
          ""
        end
      end

      def time_difference(value, time_format_on=true)
        seconds = value % 60
        value = (value - seconds) / 60
        minutes = value % 60
        value = (value - minutes) / 60
        hours = value % 24
        value = (value - hours) / 24
        days = value % 7
        more_hours = hours + days * 24 if days > 0

        if time_format_on
          "-#{hours.to_i}h#{minutes.to_i}m, #{@job.started_at.localtime.strftime("%Y-%m-%d %r")}"
        else
          if days < 2
            "-#{more_hours.to_i}h#{minutes.to_i}m#{seconds.to_i}s"
          else
            "-#{days.to_i}d#{hours.to_i}h#{minutes.to_i}m#{seconds.to_i}s"
          end
        end
      end

      def has_started?
        @job.started_at.present?
      end

      def queued_time
        created_at.localtime.strftime("%Y-%m-%d %r")
      end

      def run_time
        if @job.started_at.present?
          if @job.finished_at.present?
            time_difference(@job.finished_at - @job.started_at, false)[1..-1]
          else
            time_difference(Time.zone.now - @job.started_at, false)[1..-1]
          end
        else
          ""
        end
      end

      def finished_at
        if value = @job.finished_at
          "#{time_ago_in_words(value, true)} ago, #{value.localtime.strftime("%Y-%m-%d %r")}"
        else
          ""
        end
      end

      def affinities
        @job.historical_job_affinity_tabs.map do |tab|
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

      def tags
        if @job.tags.present?
          # Only show custom visible tags
          job_tags = @job.tags.gsub(/[{}]/,'').split(',')
          (job_tags.select { |elem| !['$', '_'].include?elem[0] }).join(', ')
        else
          nil
        end
      end

      def runner
        if @job.machine_runner_invocation.present?
          machine = @job.machine_runner_invocation.machine_runner.machine
          if machine.present?
            if machine.server_name.present?
              machine.server_name.to_s
            else
              if Rails.env == 'development'
                "localhost:#{Rails::Server.new.options[:Port]}"
              else
                machine.server_address
              end
            end
          end
        else
          ''
        end
      end

    end
  end
end
