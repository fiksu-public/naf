require 'timeout'

module Process::Naf
  class Runner < ::Af::Application

    JOB_LOG_MAX_SIZE = 10_000

    attr_accessor :machine

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
    opt :schedule_fudge_scale,
        "amount of time to look back in schedule for run_start_minute schedules (scaled to --check-schedule-period)",
        default: 5
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
    end

    def work
      check_gc_configurations

      @machine = ::Naf::Machine.find_by_server_address(@server_address)

      unless machine.present?
        logger.fatal "This machine is not configued correctly (ipaddress: #{@server_address})."
        logger.fatal "Please update #{::Naf::Machine.table_name} with an entry for this machine."
        logger.fatal "Exiting..."
        exit 1
      end

      machine.lock_for_runner_use
      begin
        wind_down_runners

        # Create a machine runner, if it doesn't exist
        machine_runner = ::Naf::MachineRunner.
          find_or_create_by_machine_id_and_runner_cwd(machine_id: machine.id,
                                                      runner_cwd: Dir.pwd)
        # Create an invocation for this runner
        invocation = ::Naf::MachineRunnerInvocation.
          create!({ machine_runner_id: machine_runner.id, pid: Process.pid }.merge!(retrieve_invocation_information))
      ensure
        machine.unlock_for_runner_use
      end

      begin
        work_machine(invocation)
      ensure
        invocation.dead_at = Time.zone.now
        invocation.save!
        terminate_old_processes(invocation.id)
      end
    end

    def check_gc_configurations
      unless @disable_gc_modifications
        # These configuration changes will help forked processes, not the runner
        ENV['RUBY_HEAP_MIN_SLOTS'] = '500000'
        ENV['RUBY_HEAP_SLOTS_INCREMENT'] = '250000'
        ENV['RUBY_HEAP_SLOTS_GROWTH_FACTOR'] = '1'
        ENV['RUBY_GC_MALLOC_LIMIT'] = '50000000'
      end
    end

    def wind_down_runners
      machine.machine_runners.each do |machine_runner|
        machine_runner.machine_runner_invocations.each do |invocation|
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
              terminate_old_processes(invocation.id)
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

    def work_machine(invocation)
      machine.mark_alive
      machine.mark_up

      # Make sure no processes are thought to be running on this machine
      terminate_old_processes if @kill_all_runners

      logger.info escape_html("working: #{machine}")

      @children = {}
      @threads = {}

      at_exit {
        ::Af::Application.singleton.emergency_teardown
      }

      @job_fetcher = ::Logical::Naf::JobFetcher.new(machine)

      while true
        break unless work_machine_loop(invocation)
        GC.start
      end

      logger.info "runner quitting"
    end

    def work_machine_loop(invocation)
      machine.reload

      # Check machine status
      if !machine.enabled
        logger.warn escape_html("this machine is disabled #{machine}")
        return false
      elsif machine.marked_down
        logger.warn escape_html("this machine is marked down #{machine}")
        return false
      end

      machine.mark_alive

      check_log_level

      invocation.reload
      if invocation.wind_down_at.present?
        logger.warn "invocation asked to wind down"
        if @children.length == 0
          return false;
        end
      end

      check_schedules if invocation.wind_down_at.blank?

      cleanup_dead_children

      start_new_jobs(invocation)

      return true
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
      if ::Naf::Machine.is_it_time_to_check_schedules?(@check_schedules_period.minutes)
        logger.debug "it's time to check schedules"
        if ::Naf::ApplicationSchedule.try_lock_schedules
          logger.debug_gross "checking schedules"
          machine.mark_checked_schedule
          ::Naf::ApplicationSchedule.unlock_schedules

          # check scheduled tasks
          should_be_queued.each do |application_schedule|
            logger.info escape_html("scheduled application: #{application_schedule}")
            begin
              naf_boss = ::Logical::Naf::ConstructionZone::Boss.new
              # this doesn't work very well for run_group_limits in the thousands
              Range.new(0, application_schedule.application_run_group_limit || 1, true).each do
                naf_boss.enqueue_application_schedule(application_schedule)
              end
            rescue ::Naf::HistoricalJob::JobPrerequisiteLoop => jpl
              logger.error escape_html("#{machine} couldn't queue schedule because of prerequisite loop: #{jpl.message}")
              logger.warn jpl
              application_schedule.enabled = false
              application_schedule.save!
              logger.alarm escape_html("Application Schedule disabled due to loop: #{application_schedule}")
            end
          end

          # check the runner machines
          ::Naf::Machine.enabled.up.each do |runner_to_check|
            if runner_to_check.is_stale?(@runner_stale_period.minutes)
              logger.alarm escape_html("runner is stale for #{@runner_stale_period} minutes, #{runner_to_check}")
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
            # XXX is there a race condition where a child process exits
            # XXX has not set pid or status yet and timeout fires?
            # XXX i bet there is
            # XXX so this code is here:
            dead_children = []
            @children.each do |pid, child|
              unless is_job_process_alive?(child)
                dead_children << child
              end
            end

            unless dead_children.blank?
              logger.error escape_html("#{machine}: dead children even with timeout during waitpid2(): #{dead_children.inspect}")
              logger.warn "this isn't necessarily incorrect -- look for the pids to be cleaned up next round, if not: call it a bug"
            end

            break
          rescue Errno::ECHILD => e
            logger.error escape_html("#{machine} No child when we thought we had children #{@children.inspect}")
            logger.warn e
            pid = @children.first.try(:first)
            status = nil
            logger.warn "pulling first child off list to clean it up: pid=#{pid}"
          end

          if pid
            begin
              child_job = @children.delete(pid)

              if child_job.present?
                # Update job tags
                child_job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:work]])

                if status.nil? || status.exited? || status.signaled?
                  logger.info { escape_html("cleaning up dead child: #{child_job.reload}") }
                  finish_job(child_job,
                             { exit_status: (status && status.exitstatus), termination_signal: (status && status.termsig) })

                  thread = @threads.delete(pid)
                  logger.detail escape_html("cleaning up threads: #{thread.inspect}")
                  logger.detail escape_html("thread list: #{Thread.list}")
                  thread.join
                else
                  # this can happen if the child is sigstopped
                  logger.warn escape_html("child waited for did not exit: #{child_job}, status: #{status.inspect}")
                end
              else
                # XXX ERROR no child for returned pid -- this can't happen
                logger.warn "child pid: #{pid}, status: #{status.inspect}, not managed by this runner"
              end
            rescue ActiveRecord::ActiveRecordError => are
              raise
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

    def start_new_jobs(invocation)
      # start new jobs
      logger.detail "starting new jobs, num children: #{@children.length}/#{machine.thread_pool_size}"
      # XXX while @children.length < machine.thread_pool_size && memory_available_to_spawn? && invocation.wind_down_at.blank?
      while ::Naf::RunningJob.where(started_on_machine_id: machine.id).count < machine.thread_pool_size &&
        memory_available_to_spawn? && invocation.wind_down_at.blank?

        logger.debug_gross "fetching jobs because: children: #{@children.length} < #{machine.thread_pool_size} (poolsize)"
        begin
          running_job = @job_fetcher.fetch_next_job

          unless running_job.present?
            logger.debug_gross "no more jobs to run"
            break
          end

          logger.info escape_html("starting new job : #{running_job.inspect}")

          # fork and run
          pid, stdin, stdout, stderr = running_job.historical_job.spawn
          stdin.close

          # Reset NAF_JOB_ID
          ENV.delete('NAF_JOB_ID')
          if pid
            @children[pid] = running_job
            running_job.pid = pid
            running_job.historical_job.pid = pid
            running_job.historical_job.failed_to_start = false
            running_job.historical_job.machine_runner_invocation_id = invocation.id
            logger.info escape_html("job started : #{running_job}")
            running_job.save!
            running_job.historical_job.save!

            # Spawn a thread to output the log of each job to files.
            #
            # Make sure not to execute any database calls inside this
            # block, as it will start an ActiveRecord connection for each
            # thread and eventually raise a ConnetionTimeoutError, resulting
            # the runner to exit.
            thread = Thread.new do
              log_output_until_job_finishes(running_job.id, stdout, stderr)
            end
            @threads[pid] = thread
          else
            # should never get here (well, hopefully)
            logger.error escape_html("#{machine}: failed to execute #{running_job}")

            finish_job(running_job, { failed_to_start: true })
          end
        rescue ActiveRecord::ActiveRecordError => are
          raise
        rescue StandardError => e
          # XXX rescue for various issues
          logger.error escape_html("#{machine}: failure during job start")
          logger.warn e
        end
      end
      logger.debug_gross "done starting jobs"
    end

    def log_output_until_job_finishes(job_id, stdout, stderr)
      find_or_create_directories(job_id)

      # Track the number of logs
      line_number = 1
      # Each log file path is unique
      job_log_file = File.open("#{::Naf::PREFIX_PATH}/jobs/#{job_id}/#{line_number}_#{Time.zone.now}.json", 'wb')

      # Continue reading logs from stdout/stderror until it reaches end of file
      while true
        read_pipes = []
        read_pipes << stdout if stdout
        read_pipes << stderr if stderr
        return if (read_pipes.length == 0)

        error_pipes = read_pipes.clone
        read_array, write_array, error_array = Kernel.select(read_pipes, nil, error_pipes, 1)

        unless error_array.blank?
          logger.error escape_html("job(#{job_id}): select returned error for #{error_pipes.inspect} (read_pipes: #{read_pipes.inspect})")
          # XXX we should probably close the errored FDs
        end

        unless read_array.blank?
          for r in read_array do
            log_lines = ""
            job_log_file = check_job_log(job_log_file, job_id, line_number)

            begin
              # Read from stdout in chunks
              logs = r.read_nonblock(10240).split("\n")
              # Parse each log line into JSON
              logs.each do |log|
                log_lines << JSON.pretty_generate({
                  line_number: line_number,
                  output_time: Time.zone.now.strftime("%Y-%m-%d %H:%M:%S.%L"),
                  message: log.strip,
                  job_id: job_id
                })
                line_number += 1
              end
            rescue Errno::EAGAIN
            rescue Errno::EINTR
            rescue EOFError => eof
              stdout = nil if r == stdout
              stderr = nil if r == stderr
            else
              job_log_file.write(log_lines)
              # Since the file is buffered, we want to tell it to write in chunks.
              # Files should be shown as the scripts runs.
              job_log_file.flush
            end
          end
        end
      end

      job_log_file.close
    end

    def find_or_create_directories(job_id)
      # Create the directory path if it doesn't exist
      FileUtils.mkdir_p("#{::Naf::PREFIX_PATH}/jobs/#{job_id}") unless File.directory?("#{::Naf::PREFIX_PATH}/jobs/#{job_id}")
    end

    def check_job_log(file, job_id, line_number)
      # When a file gets too large, close it and continue writing to another file
      if file.size > JOB_LOG_MAX_SIZE
        file.close
        file = File.open("#{::Naf::PREFIX_PATH}/jobs/#{job_id}/#{line_number}_#{Time.zone.now}.json", 'wb')
      end

      file
    end

    # XXX update_all doesn't support "from_partition" so we have this helper
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
      running_job.historical_job.remove_all_tags
      running_job.historical_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])

      ::Naf::HistoricalJob.transaction do
        update_historical_job(updates.merge({ finished_at: Time.zone.now }), running_job.id)
        running_job.delete
      end

      running_job.historical_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:cleanup]])
    end

    # kill(0, pid) seems to fail during at_exit block
    # so this shoots from the hip
    def emergency_teardown
      return if @children.length == 0
      logger.warn "emergency teardown of #{@children.length} job(s)"
      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "TERM")
      end
      sleep(2)
      @children.clone.each do |pid, child|
        send_signal_and_maybe_clean_up(child, "KILL")

        # force job down
        finish_job(child)
      end
    end

    def terminate_old_processes(invocation_id = nil)
      # check if any processes are hanging around and ask them
      # politely if they will please terminate
      jobs = assigned_jobs(invocation_id)
      if jobs.length == 0
        logger.detail "no jobs to remove"
        return
      end
      logger.info "number of old jobs to sift through: #{jobs.length}"
      jobs.each do |job|
        logger.detail escape_html("job still around: #{job}")
        if job.request_to_terminate == false
          logger.warn "politely asking process: #{job.pid} to terminate itself"
          job.request_to_terminate = true
          job.save!
        end
      end

      # wait
      (1..@wait_time_for_processes_to_terminate).each do |i|
        num_assigned_jobs = assigned_jobs(invocation_id).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/#{@wait_time_for_processes_to_terminate}: sleeping 1 second while we wait for " +
          "#{num_assigned_jobs} assigned job(s) to terminate as requested"
        sleep(1)
      end

      # nudge them to terminate
      jobs = assigned_jobs(invocation_id)
      if jobs.length == 0
        logger.debug_gross "assigned jobs have exited after asking to terminate nicely"
        return
      end
      jobs.each do |job|
        logger.warn escape_html("sending SIG_TERM to process: #{job}")
        send_signal_and_maybe_clean_up(job, "TERM")
      end

      # wait
      (1..5).each do |i|
        num_assigned_jobs = assigned_jobs(invocation_id).length
        return if num_assigned_jobs == 0
        logger.debug_medium "#{i}/5: sleeping 1 second while we wait for #{num_assigned_jobs} assigned job(s) to terminate from SIG_TERM"
        sleep(1)
      end

      # kill with fire
      assigned_jobs(invocation_id).each do |job|
        logger.alarm escape_html("sending SIG_KILL to process: #{job}")
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

    def assigned_jobs(invocation_id)
      if invocation_id.present?
        return ::Naf::RunningJob.started_on_invocation(invocation_id).select do |job|
          is_job_process_alive?(job)
        end
      else
        return ::Naf::RunningJob.assigned_jobs(machine).select do |job|
          is_job_process_alive?(job)
        end
      end
    end

    def should_be_queued
      not_finished_applications = ::Naf::HistoricalJob.
        queued_between(Time.zone.now - Naf::HistoricalJob::JOB_STALE_TIME, Time.zone.now).
        where("finished_at IS NULL AND request_to_terminate = false").
        find_all{ |job| job.application_id.present? }.
        index_by{ |job| job.application_id }

      application_last_runs = ::Naf::HistoricalJob.application_last_runs.
        index_by{ |job| job.application_id }

      # find the run_interval based schedules that should be queued
      # select anything that isn't currently running and completed
      # running more than run_interval minutes ago
      relative_schedules_what_need_queuin = ::Naf::ApplicationSchedule.where(enabled: true).relative_schedules.select do |schedule|
        (not_finished_applications[schedule.application_id].nil? &&
          (application_last_runs[schedule.application_id].nil? ||
            (Time.zone.now - application_last_runs[schedule.application_id].finished_at) > (schedule.run_interval.minutes)))
      end

      # find the run_start_minute based schedules
      # select anything that
      #  isn't currently running (or queued) AND
      #  hasn't run since run_start_time AND
      #  should have been run by now AND
      #  that should have run within fudge period AND
      exact_schedules_what_need_queuin = ::Naf::ApplicationSchedule.where(enabled: true).exact_schedules.select do |schedule|
        (not_finished_applications[schedule.application_id].nil? &&
          (application_last_runs[schedule.application_id].nil? ||
            ((Time.zone.now.to_date + schedule.run_start_minute.minutes) >= application_last_runs[schedule.application_id].finished_at)) &&
          (Time.zone.now - (Time.zone.now.to_date + schedule.run_start_minute.minutes)) >= 0.seconds &&
          ((Time.zone.now - (Time.zone.now.to_date + schedule.run_start_minute.minutes)) <= (@check_schedules_period * @schedule_fudge_scale).minutes)
        )
      end

      foreman = ::Logical::Naf::ConstructionZone::Foreman.new()
      return (relative_schedules_what_need_queuin + exact_schedules_what_need_queuin).select do |schedule|
        schedule.enqueue_backlogs || !foreman.limited_by_run_group?(schedule.application_run_group_restriction,
                                                                    schedule.application_run_group_name,
                                                                    schedule.application_run_group_limit)
      end
    end

    def memory_available_to_spawn?
      Facter.clear
      memory_size = Facter.memorysize_mb.to_f
      memory_free = Facter.memoryfree_mb.to_f
      memory_free_percentage = (memory_free / memory_size) * 100.0

      if (memory_free_percentage >= @minimum_memory_free)
        logger.detail "memory available: #{memory_free_percentage}% (free) >= #{@minimum_memory_free}% (min percent)"
        return true
      end
      logger.alarm "#{Facter.hostname}.#{Facter.domain}: not enough memory to spawn: #{memory_free_percentage}% (free) < #{@minimum_memory_free}% (min percent)"

      return false
    end

    def escape_html(str)
      CGI::escapeHTML(str)
    end

  end
end
