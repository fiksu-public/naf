# A wrapper around Naf::Job
# used for rendering in views

module Logical
  class Job
    include ActionView::Helpers::DateHelper
    
    COLUMNS = [:id, :server, :pid, :queued_time, :title, :started_at, :finished_at, :status]

    ATTRIBUTES = [:title, :id, :status, :server, :pid, :queued_time, :started_at, :finished_at,  :script_type_name, :log_level, :machine_started_on_server_address, :machine_started_on_server_name, :application_run_group_restriction_name]

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
      if @job.started_at and (not @job.finished_at)
        "Running"
      elsif (not @job.started_at) and (not @job.finished_at) and @job.failed_to_start
        "Failed to Start"
      elsif @job.exit_status and @job.exit_status > 0
        "Error"
      elsif @job.started_at and @job.finished_at
        "Finished"
      else
        "Queued"
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
      case search[:status].to_sym
      when :failed_to_start
        job_scope = ::Naf::Job.where(:failed_to_start => true)
      when :error
        job_scope = ::Naf::Job.where("exit_status > 0")
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

    def to_detailed_hash
      Hash[ ATTRIBUTES.map{ |m| [m, send(m)] } ]
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

    def finished_at
      if value = @job.finished_at
        "#{time_ago_in_words(value, true)} ago"
      else
        ""
      end
    end

  end
end
