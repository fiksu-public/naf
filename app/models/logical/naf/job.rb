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

      ORDER = { '3' => "created_at", '5' => "started_at", '6' => "finished_at" }
     
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
        if application and application.application_schedule
          application.application_schedule.title
        else
          command
        end
      end
      
      def server
        if started_on_machine 
          name = started_on_machine.server_name
          if name and name.length > 0
            name
          else
            started_on_machine.server_address
          end
        end
      end
      
      # Given search, a hash of the search query for jobs on the queue,
      # build up and return the ActiveRecord scope
      #
      # We eventually build up these results over created_at/1.week partitions.
      def self.search(search)
        job_scope = self.get_job_scope(search)
        order, direction = search[:order], search[:direction]
        job_scope = job_scope.order("#{order} #{direction}").limit(search[:limit]).offset(search[:offset].to_i*search[:limit].to_i)
        FILTER_FIELDS.each do |field|
          job_scope = job_scope.where(field => search[field]) if search[field].present?
        end
        SEARCH_FIELDS.each do |field|
          job_scope = job_scope.where(["lower(#{field}) ~ ?", search[field].downcase]) if search[field].present?
        end
        # Now return instantiations of all the logical job wrappers 
        # from the job scope
        return job_scope.map{|physical_job| new(physical_job) }
      end

      def self.total_display_records(search)
        job_scope = self.get_job_scope(search)
        FILTER_FIELDS.each do |field|
          job_scope = job_scope.where(field => search[field]) if search[field].present?
        end
        SEARCH_FIELDS.each do |field|
          job_scope = job_scope.where(["lower(#{field}) ~ ?", search[field].downcase]) if search[field].present?
        end

        job_scope.count
      end

      def self.get_job_scope(search)
        status = search[:status].nil? ? :all : search[:status]
        case status.to_sym
          when :queued
            job_scope = ::Naf::Job.queued_and_running
          when :finished
            job_scope = ::Naf::Job.finished
          when :errored
            job_scope = ::Naf::Job.errored
          else
            job_scope = ::Naf::Job.scoped
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
          name = job_affinity.affinity_classification_name + '_' + job_affinity.short_name_if_it_exist

          name
        end.join(", \n")
      end

    end
  end
end
