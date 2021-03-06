require 'timeout'

module Process::Naf
  class Runner < ::Af::Application

    attr_accessor :machine,
                  :current_invocation,
                  :last_cleaned_up_processes

    #----------------
    # *** Options ***
    #+++++++++++++++++

    opt :wait_time_for_processes_to_terminate,
        "time between askign processes to terminate and sending kill signals",
        argument_note: "SECONDS",
        default: 120
    opt :check_schedules_period,
        "time between checking schedules",
        argument_note: "MINUTES",
        default: 1
    opt :runner_stale_period,
        "amount of time to consider a machine out of touch if it hasn't updated its machine entry",
        argument_note: "MINUTES",
        default: 10
    opt :loop_sleep_time,
        "runner main loop sleep time",
        argument_note: "SECONDS",
        default: 30
    opt :server_address,
        "set the machines server address (dangerous)",
        type: :string,
        default: ::Naf::Machine.machine_ip_address,
        hidden: true
    opt :minimum_memory_free,
        "percentage of memory free below which will limit process spawning",
        default: 15.0,
        argument_note: "PERCENT"
    opt :disable_gc_modifications,
        "don't modify ruby GC parameters",
        default: false
    opt :kill_all_runners,
        "don't wait for runners to wind down and finish running their jobs",
        default: false
    opt :invocation_uuid,
        "unique identifer used for runner logs",
        default: `uuidgen`

    def initialize
      super
      opt :log_configuration_files, default: ["af.yml",
                                              "af-#{Rails.env}.yml",
                                              "naf.yml",
                                              "naf-#{Rails.env}.yml",
                                              "nafrunner.yml",
                                              "nafrunner-#{Rails.env}.yml",
                                              "#{af_name}.yml",
                                              "#{af_name}-#{Rails.env}.yml"]
      @last_machine_log_level = nil
      @metric_send_delay = ::Naf.configuration.metric_send_delay
    end

    def work
      check_gc_configurations

      @machine = ::Naf::Machine.find_by_server_address(@server_address)

      @metric_sender = ::Logical::Naf::MetricSender.new(@metric_send_delay, @machine)

      unless machine.present?
        logger.fatal "This machine is not configued correctly (ipaddress: #{@server_address})."
        logger.fatal "Please update #{::Naf::Machine.table_name} with an entry for this machine."
        logger.fatal "Exiting..."
        exit 1
      end

      machine.lock_for_runner_use do
        cleanup_old_processes
        remove_invalid_running_jobs
        wind_down_runners

        # Create a machine runner, if it doesn't exist
        machine_runner = ::Naf::MachineRunner.
          find_or_create_by_machine_id_and_runner_cwd(machine_id: machine.id,
                                                      runner_cwd: Dir.pwd)
        # Create an invocation for this runner
        @current_invocation = ::Naf::MachineRunnerInvocation.
          create!({ machine_runner_id: machine_runner.id,
                    pid: Process.pid,
                    uuid: @invocation_uuid }.merge!(retrieve_invocation_information))
      end

      begin
        work_machine
      ensure
        @current_invocation.dead_at = Time.zone.now
        @current_invocation.save!
        cleanup_old_processes
      end
    end

    def remove_invalid_running_jobs
      logger.debug "looking for invalid running jobs"
      ::Naf::RunningJob.
        joins("INNER JOIN #{Naf.schema_name}.historical_jobs AS hj ON hj.id = #{Naf.schema_name}.running_jobs.id").
        where('finished_at IS NOT NULL AND hj.started_on_machine_id = ?', @machine.id).readonly(false).each do |job|
          logger.debug "removing invalid job #{job.inspect}"
          job.delete
      end
    end

    def check_gc_configurations
      logger.debug "checking garbage collection configurations"
      unless @disable_gc_modifications
        # These configuration changes will help forked processes, not the runner
        ENV['RUBY_HEAP_MIN_SLOTS'] = '500000'
        ENV['RUBY_HEAP_SLOTS_INCREMENT'] = '250000'
        ENV['RUBY_HEAP_SLOTS_GROWTH_FACTOR'] = '1'
        ENV['RUBY_GC_MALLOC_LIMIT'] = '50000000'
      end
    end

    def cleanup_old_processes(created_at_interval = 1.month, marked_dead_interval = 24.hours)
      @last_cleaned_up_processes = Time.zone.now
      logger.debug "cleaning up old processes"
      ::Naf::MachineRunner.where("created_at >= ?", Time.zone.now - created_at_interval).each do |runner|
        runner.machine_runner_invocations.recently_marked_dead(marked_dead_interval).each do |invocation|
          terminate_old_processes(invocation)
        end
      end
    end

    def wind_down_runners
      machine.machine_runners.each do |runner|
        runner.machine_runner_invocations.each do |invocation|
          if invocation.dead_at.blank?
            begin
              retval = Process.kill(0, invocation.pid)
              logger.detail "#{retval} = kill(0, #{invocation.pid}) -- process alive, marking runner invocation as winding down"
              invocation.wind_down_at = Time.zone.now
              invocation.save!
            rescue Errno::ESRCH
              logger.detail "ESRCH = kill(0, #{invocation.pid}) -- marking runner invocation as not running"
              invocation.dead_at = Time.zone.now
              invocation.save!
              terminate_old_processes(invocation)
            end
          end
        end
      end
    end

    def retrieve_invocation_information
      begin
        repository_name = (`git remote -v`).slice(/:\S+/).sub('.git','')[1..-1]
        if repository_name.match(/fatal/)
          repository_name = nil
        end
      rescue
        repository_name = nil
      end
      branch_name = (`git rev-parse --abbrev-ref HEAD`).strip
      if branch_name.match(/fatal/)
        branch_name = nil
      end
      commit_information = (`git log --pretty="%H" -n 1`).strip
      if commit_information.match(/fatal/)
        commit_information = nil
      end
      deployment_tag = (`git describe --abbrev=0 --tag 2>&1`).strip
      if deployment_tag.match(/fatal: No names found, cannot describe anything/)
        deployment_tag = nil
      end

      {
        repository_name: repository_name,
        branch_name: branch_name,
        commit_information: commit_information,
        deployment_tag: deployment_tag
      }
    end

    def work_machine
      machine.mark_alive
      machine.mark_up

      # Make sure no processes are thought to be running on this machine
      terminate_old_processes(machine) if @kill_all_runners

      logger.info "working: #{machine}"

      @children = {}

      at_exit {
        ::Af::Application.singleton.emergency_teardown
      }

      @job_fetcher = ::Logical::Naf::JobFetcher.new(machine)

      while true
        break unless work_machine_loop
        GC.start
      end

      logger.info "runner quitting"
    end

    def work_machine_loop
      machine.reload

      # Check machine status
      if !machine.enabled
        logger.warn "this machine is disabled #{machine}"
        return false
      elsif machine.marked_down
        logger.warn "this machine is marked down #{machine}"
        return false
      end

      logger.debug "marking machine alive"
      machine.mark_alive

      check_log_level

      @current_invocation.reload
      if current_invocation.wind_down_at.present?
        logger.warn "invocation asked to wind down"
        if @children.length == 0
          return false;
        end
      else
        check_schedules
        start_new_jobs
      end

      send_metrics

      cleanup_dead_children
      cleanup_old_processes(1.week, 75.minutes) if (Time.zone.now - @last_cleaned_up_processes) > 1.hour

      return true
    end

    def send_metrics
      # Only send metrics if not winding down, or winding down and only runner.
      logger.debug "checking whether it's time to send metrics"
      @current_invocation.reload
      if @current_invocation.wind_down_at.present?
        return nil if @machine.machine_runners.running.count > 0
      end
      logger.debug "sending metrics"
      @metric_sender.send_metrics
    end

    def check_log_level
      if machine.log_level != @last_machine_log_level
        @last_machine_log_level = machine.log_level
        unless @last_machine_log_level.blank?
          logging_configurator.parse_and_set_logger_levels(@last_machine_log_level)
        end
      end
    end

    def check_schedules
      logger.debug "last time schedules were checked: #{::Naf::Machine.last_time_schedules_were_checked}"
      if ::Naf::Machine.is_it_time_to_check_schedules?(@check_schedules_period.minutes)
        logger.debug "it's time to check schedules"
        if ::Naf::ApplicationSchedule.try_lock_schedules
          logger.debug_gross "checking schedules"
          machine.mark_checked_schedule
          ::Naf::ApplicationSchedule.unlock_schedules

          # check scheduled tasks
          ::Naf::ApplicationSchedule.should_be_queued.each do |application_schedule|
            logger.info "scheduled application: #{application_schedule}"
            begin
              naf_boss = ::Logical::Naf::ConstructionZone::Boss.new
              # this doesn't work very well for run_group_limits in the thousands
              Range.new(0, application_schedule.application_run_group_quantum || 1, true).each do
                naf_boss.enqueue_application_schedule(application_schedule)
              end
            rescue ::Naf::HistoricalJob::JobPrerequisiteLoop => jpl
              logger.error "#{machine} couldn't queue schedule because of prerequisite loop: #{jpl.message}"
              logger.warn jpl
              application_schedule.enabled = false
              application_schedule.save!
              logger.alarm "Application Schedule disabled due to loop: #{application_schedule}"
            end
          end

          # check the runner machines
          ::Naf::Machine.enabled.up.each do |runner_to_check|
            if runner_to_check.is_stale?(@runner_stale_period.minutes)
              logger.alarm "runner is stale for #{@runner_stale_period} minutes, #{runner_to_check}"
              runner_to_check.mark_machine_down(machine)
            end
          end
        end
      end
    end

    def cleanup_dead_children
      # clean up children that have exited
      logger.detail "cleaning up dead children: #{@children.length}"

      if @children.length > 0
        while @children.length > 0
          pid = nil
          status = nil
          begin
            Timeout::timeout(@loop_sleep_time) do
              pid, status = Process.waitpid2(-1)
            end
          rescue Timeout::Error
            check_dead_children_not_exited_properly
            break
          rescue Errno::ECHILD => e
            logger.error "#{machine} No child when we thought we had children #{@children.inspect}"
            logger.warn e
            pid = @children.first.try(:first)
            status = nil
            logger.warn "pulling first child off list to clean it up: pid=#{pid}"
          end

          if pid
            begin
              cleanup_dead_child(pid, status)
            rescue ActiveRecord::ActiveRecordError => are
              logger.error "Failure during cleaning up of dead child with pid: #{pid}, status: #{status}"
              logger.error "#{are.message}"
            rescue StandardError => e
              # XXX just incase a job control failure -- more code here
              logger.error "some failure during child clean up"
              logger.warn e
            end
          end
        end
      else
        logger.detail "sleeping in loop: #{@loop_sleep_time} seconds"
        sleep(@loop_sleep_time)
      end
    end

    # XXX is there a race condition where a child process exits
    # XXX has not set pid or status yet and timeout fires?
    # XXX i bet there is
    # XXX so this code is here:
    def check_dead_children_not_exited_properly
      dead_children = []
      @children.each do |pid, child|
        unless is_job_process_alive?(child)
          dead_children << child
        end
      end

      unless dead_children.blank?
        logger.error "#{machine}: dead children even with timeout during waitpid2(): #{dead_children.inspect}"
        logger.warn "this isn't necessarily incorrect -- look for the pids to be cleaned up next round, if not: call it a bug"
      end
    end

    def cleanup_dead_child(pid, status)
      child_job = @children.delete(pid)

      if child_job.present?
        # Update job tags
        child_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:work]])

        if status.nil? || status.exited? || status.signaled?
          logger.info { "cleaning up dead child: #{child_job.inspect}" }
          finish_job(child_job,
                     { exit_status: (status && status.exitstatus), termination_signal: (status && status.termsig) })
          if status && status.exitstatus > 0 && !child_job.request_to_terminate
            @metric_sender.statsd.event("Naf Job Error",
                  "#{child_job.inspect} finished with non-zero exit status.",
                  alert_type: "error",
                  tags: (::Naf.configuration.metric_tags << "naf:joberror"))
          end
        else
          # this can happen if the child is sigstopped
          logger.warn "child waited for did not exit: #{child_job.inspect}, status: #{status.inspect}"
        end
      else
        # XXX ERROR no child for returned pid -- this can't happen
        logger.warn "child pid: #{pid}, status: #{status.inspect}, not managed by this runner"
      end
    end

    def start_new_jobs
      logger.detail "starting new jobs, num children: #{@children.length}/#{machine.thread_pool_size}"
      while ::Naf::RunningJob.where(started_on_machine_id: machine.id).count < machine.thread_pool_size &&
        memory_available_to_spawn? && current_invocation.wind_down_at.blank?

        logger.debug_gross "fetching jobs because: children: #{@children.length} < #{machine.thread_pool_size} (poolsize)"
        begin
          running_job = @job_fetcher.fetch_next_job

          unless running_job.present?
            logger.debug_gross "no more jobs to run"
            break
          end

          logger.info "starting new job : #{running_job.inspect}"

          pid = running_job.historical_job.spawn
          if pid.present?
            @children[pid] = running_job
            running_job.pid = pid
            running_job.historical_job.pid = pid
            running_job.historical_job.failed_to_start = false
            running_job.historical_job.machine_runner_invocation_id = current_invocation.id
            running_job.save!
            running_job.historical_job.save!
            logger.info "job started : #{running_job.inspect}"
          else
            # should never get here (well, hopefully)
            logger.error "#{machine}: failed to execute #{running_job.inspect}"

            finish_job(running_job, { failed_to_start: true })
          end
        rescue ActiveRecord::ActiveRecordError => are
          raise
        rescue StandardError => e
          # XXX rescue for various issues
          logger.error "#{machine}: failure during job start"
          logger.warn e
        end
      end
      logger.debug_gross "done starting jobs"
    end

    # update_all doesn't support "from_partition" so we have this helper
    def update_historical_job(updates, historical_job_id)
      updates[:updated_at] = Time.zone.now
      update_columns = updates.map{ |k,v| "#{k} = ?" }.join(", ")
      update_sql = <<-SQL
        UPDATE
          #{::Naf::HistoricalJob.partition_table_name(historical_job_id)}
        SET
          #{update_columns}
        WHERE
          id = ?
      SQL
      ::Naf::HistoricalJob.find_by_sql([update_sql] + updates.values + [historical_job_id])
    end

    def finish_job(running_job, updates = {})
      # Check to see if running job still exists
      job = ::Naf::RunningJob.find_by_id(running_job.id)
      if job.present?
        job.lock_for_runner_use do
          ::Naf::HistoricalJob.transaction do
            update_historical_job(updates.merge({ finished_at: Time.zone.now }), job.id)
            job.delete
          end
        end
      else
        job = ::Naf::HistoricalJob.find_by_id(running_job.id)
        # This does not seem to be need, but just for extra measure
        if job.present?
          job.lock_for_runner_use do
            ::Naf::HistoricalJob.transaction do
              update_historical_job(updates.merge({ finished_at: Time.zone.now }), job.id)
            end
          end
        end
      end
    end

    # kill(0, pid) seems to fail during at_exit block
    # so this shoots from the hip
    def emergency_teardown
      return if @children.length == 0
      logger.warn "emergency teardown of #{@children.length} job(s)"
      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "TERM")
      end

      # Wait 2 seconds
      sleep(2)

      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "KILL")

        # force job down
        finish_job(child)
      end
    end

    def terminate_old_processes(record)
      # check if any processes are hanging around and ask them
      # politely if they will please terminate
      jobs = assigned_jobs(record)
      if jobs.length == 0
        logger.detail "no jobs to remove"
        return
      end

      logger.info "number of old jobs to sift through: #{jobs.length}"
      jobs.each do |job|
        logger.detail "job still around: #{job.inspect}"
        if job.request_to_terminate == false
          logger.warn "politely asking process: #{job.pid} to terminate itself"
          job.request_to_terminate = true
          job.save!
        end
      end

      # wait
      (1..@wait_time_for_processes_to_terminate).each do |i|
        num_assigned_jobs = assigned_jobs(record).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/#{@wait_time_for_processes_to_terminate}: sleeping 1 second while we wait for " +
          "#{num_assigned_jobs} assigned job(s) to terminate as requested"
        sleep(1)
      end

      # nudge them to terminate
      jobs = assigned_jobs(record)
      if jobs.length == 0
        logger.debug_gross "assigned jobs have exited after asking to terminate nicely"
        return
      end
      jobs.each do |job|
        logger.warn "sending SIG_TERM to process: #{job.inspect}"
        send_signal_and_maybe_clean_up(job, "TERM")
      end

      # wait
      (1..5).each do |i|
        num_assigned_jobs = assigned_jobs(record).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/5: sleeping 1 second while we wait for #{num_assigned_jobs} assigned job(s) to terminate from SIG_TERM"
        sleep(1)
      end

      # kill with fire
      assigned_jobs(record).each do |job|
        logger.alarm "sending SIG_KILL to process: #{job.inspect}"
        send_signal_and_maybe_clean_up(job, "KILL")

        # job force job down
        finish_job(job)
      end
    end

    def send_signal_and_maybe_clean_up(job, signal)
      if job.pid.nil?
        finish_job(job)

        return false
      end

      begin
        retval = Process.kill(signal, job.pid)
        logger.detail "#{retval} = kill(#{signal}, #{job.pid})"
      rescue Errno::ESRCH
        logger.detail "ESRCH = kill(#{signal}, #{job.pid})"

        # job does not exist -- mark it finished
        finish_job(job)

        return false
      end

      return true
    end

    def is_job_process_alive?(job)
      return send_signal_and_maybe_clean_up(job, 0)
    end

    def assigned_jobs(record)
      if record.kind_of? ::Naf::MachineRunnerInvocation
        return ::Naf::RunningJob.started_on_invocation(record.id).readonly(false).select do |job|
          is_job_process_alive?(job)
        end
      else
        return ::Naf::RunningJob.assigned_jobs(record).select do |job|
          is_job_process_alive?(job)
        end
      end
    end

    def memory_available_to_spawn?
      Facter.clear
      memory_size = Facter.memorysize_mb.to_f
      memory_free = Facter.memoryfree_mb.to_f
      memory_free_percentage = ((memory_free + sreclaimable_memory) / memory_size) * 100.0

      if (memory_free_percentage >= @minimum_memory_free)
        logger.detail "memory available: #{memory_free_percentage}% (free) >= " +
          "#{@minimum_memory_free}% (min percent)"
        return true
      end
      logger.alarm "#{Facter.hostname}.#{Facter.domain}: not enough memory to spawn: " +
        "#{memory_free_percentage}% (free) < #{@minimum_memory_free}% (min percent)"

      return false
    end

    # Linux breaks out kernel cache-use memory into an SReclaimable stat
    # in /proc/meminfo which should be counted as free, but facter does not.
    def sreclaimable_memory
      sreclaimable = 0.0
      begin
        File.readlines('/proc/meminfo').each do |l|
          if l =~ /^(?:SReclaimable):\s+(\d+)\s+\S+/
            # Convert the memory from Kilobytes to Gigabytes and
            # store it into sreclaimable
            sreclaimable = ('%.2f' % [$1.to_f / 1024.0]).to_f
            break
          end
        end
      rescue
      end

      sreclaimable
    end
  end
end
