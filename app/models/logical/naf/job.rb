# A wrapper around Naf::Job
# used for rendering in views

module Logical
  module Naf
    class Job
      include ActionView::Helpers::DateHelper
      include ActionView::Helpers::TextHelper
      
      COLUMNS = [:id, :server, :pid, :queued_time, :title, :started_at, :finished_at, :run_time, :affinities, :status]
      
      ATTRIBUTES = [:title, :id, :status, :server, :pid, :queued_time, :command, :started_at, :finished_at,  :run_time, :exit_status, :script_type_name, :log_level, :request_to_terminate, :machine_started_on_server_address,
                    :machine_started_on_server_name, :application_run_group_name, :application_run_group_limit, :application_run_group_restriction_name]
      
      FILTER_FIELDS = [:application_type_id, :application_run_group_restriction_id, :priority, :failed_to_start, :pid, :exit_status, :request_to_terminate, :started_on_machine_id]

      SEARCH_FIELDS = [:command, :application_run_group_name]

      ORDER = { '0' => "id", '2' => "pid", '3' => "created_at", '5' => "started_at", '6' => "finished_at", '9' => "status" }

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
        if @job.request_to_terminate
          "Canceled"
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

      def run_time
        start_time = @job.started_at
        end_time = @job.finished_at
        if start_time and end_time
          return Time.at((end_time - start_time).round).utc.strftime("%H:%M:%S")
        else
          return ""
        end
      end
      
      def queued_time
        created_at.localtime.strftime("%Y-%m-%d %r")
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
              JobStatuses::FinishedLessMinute.all(conditions)
            when :running
              JobStatuses::Running.all(conditions) + "union all\n" +
              JobStatuses::FinishedLessMinute.all(conditions)
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
              JobStatuses::Finished.all(conditions)
          end
          sql << "LIMIT :limit OFFSET :offset"

          jobs = ::Naf::Job.find_by_sql([sql, values])

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
          job_scope = job_scope.select{|job| job.prerequisites.select{ |pre| pre.started_at.nil? }.size > 0 }
        end

        job_scope.count
      end

      def self.get_job_scope(search)
        status = search[:status].blank? ? :all : search[:status]
        case status.to_sym
          when :queued
            job_scope = ::Naf::Job.queued_status
          when :running
            job_scope = ::Naf::Job.running_status
          when :waiting
            job_scope = ::Naf::Job.queued_with_waiting
          when :finished
            job_scope = ::Naf::Job.finished
          when :errored
            job_scope = ::Naf::Job.errored
          else
            job_scope = ::Naf::Job.scoped
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
        physical_job = ::Naf::Job.find(id)
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
        if value = @job.started_at
          "#{time_ago_in_words(value, true)} ago"
        else
          ""
        end
      end

      def has_started?
        @job.started_at.present?
      end
      
      def finished_at
        if value = @job.finished_at
          "#{time_ago_in_words(value, true)} ago"
        else
          ""
        end
      end

      def affinities
        @job.job_affinities.map do |job_affinity|
          if job_affinity.affinity_short_name
            job_affinity.affinity_short_name
          else
            job_affinity.affinity_classification_name + '_' + job_affinity.affinity_name
          end
        end.join(", \n")
      end

    end
  end
end
