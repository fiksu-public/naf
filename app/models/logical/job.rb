# A wrapper around Naf::Job
# used for rendering in views

module Logical
  class Job
    include ActionView::Helpers::DateHelper

    FILTER_FIELDS = [:application_type_id, :application_run_group_restriction_id, :priority, :failed_to_start, :pid, :exit_status, :request_to_terminate, :started_on_machine_id]
 
    SEARCH_FIELDS = [:command, :application_run_group_name]

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
      if started_at and (not finished_at)
        "Running"
      elsif started_at and finished_at
        "Finished"
      else
        "Queued"
      end
    end

    def queued_time
      created_at
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
        if started_on_machine.server_name
          started_on_machine.server_name
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
      case search[:status].to_sym
      when :not_started
        job_scope = ::Naf::Job.not_started
      when :running
        puts "Getting all the running jobs"
        job_scope = ::Naf::Job.started.not_finished
      when :finished
        job_scope = ::Naf::Job.finished
      else
        job_scope = ::Naf::Job.scoped
      end
      order, direction = search[:order], search[:direction]
      job_scope = job_scope.order("#{order} #{direction}").limit(search[:limit]).offset(search[:offset].to_i*search[:limit].to_i)
      FILTER_FIELDS.each do |field|
        job_scope = job_scope.where(field => search[field]) if search[field].present?
      end
      SEARCH_FIELDS.each do |field|
        job_scope = job_scope.where(["lower(#{field}) ~ ?", search[field].downcase]) if search[field].present?
      end
      job_scope.map{|naf_job| new(naf_job)}
    end

    # Format the hash of a job record nicely for the table
    def to_hash
      methods = [:id, :status, :queued_time, :title, :started_at, :finished_at, :pid, :server]
      Hash[
        methods.map do |m|
          value = send(m)
          if value.blank?
            [m, '']
          else
            case m
            when :queued_time
              [m, value.localtime.strftime("%Y-%m-%d %H:%M:%S")]
            when :started_at, :finished_at
              [m, "#{time_ago_in_words(value, true)} ago"]
            else
              [m, value]
            end
          end
        end
      ]
    end


  end
end
