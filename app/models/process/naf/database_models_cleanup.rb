#
# This Naf Process Script will cleanup the invalid Naf state by removing data associated
# with several models. Therefore, it should only be used on staging and development. Naf
# can get in a bad state when database dumps or snapshots are taken while runners are still up.
#
module Process::Naf
  class DatabaseModelsCleanup < ::Process::Naf::Application

    opt :options_list, 'description of options'
    opt :job, 'cleanup data related to jobs'
    opt :runner, 'cleanup data related to runners'
    opt :machine, 'cleanup data related to machines'
    opt :all, 'cleanup data related to jobs, runners, and machines'

    def work
      if @options_list.present?
        puts "DESCRIPTION\n\tThe following options are available:\n\n" +
          "\t--job\t\t->\tRemoves data related to jobs.\n\n" +
          "\t--runner\t->\tRemoves data related to runners. Job flag (--job) needs to be present.\n\n" +
          "\t--machine\t->\tRemoves data related to machines. Runner flag (--runner) needs to be present.\n\n" +
          "\t--all\t\t->\tRemoves data related to jobs, runners, and machines."

      elsif @all.present?
        cleanup_jobs
        cleanup_runners
        cleanup_machines

      elsif can_cleanup?
        cleanup(true)
      end
    end

    private

    def can_cleanup?
      cleanup
    end

    def cleanup(data_removal = false)
      if @job.present?
        cleanup_jobs if data_removal

        if @runner.present?
          cleanup_runners if data_removal
          if @machine.present?
            cleanup_machines if data_removal
          end

        elsif @machine.present?
          logger.error "--runner flag must be present"
          return false
        end
      elsif @runner.present? || @machine.present?
        logger.error "--job flag must be present"
        return false
      else
        return false
      end

      return true
    end

    def cleanup_jobs
      logger.info "Starting to remove job data..."
      ::Naf::HistoricalJobAffinityTab.delete_all
      ::Naf::HistoricalJobPrerequisite.delete_all
      ::Naf::QueuedJob.delete_all
      ::Naf::RunningJob.delete_all
      ::Naf::HistoricalJob.delete_all
      logger.info "Finished removing job data..."
    end

    def cleanup_runners
      logger.info "Starting to remove runner data..."
      ::Naf::MachineRunnerInvocation.delete_all
      ::Naf::MachineRunner.delete_all
      logger.info "Finished removing runner data..."
    end

    def cleanup_machines
      logger.info "Starting to remove machine data..."
      ::Naf::MachineAffinitySlot.delete_all
      ::Naf::Affinity.where(
        affinity_classification_id: ::Naf::AffinityClassification.machine.id
      ).delete_all
      ::Naf::Machine.delete_all
      logger.info "Finished removing machine data..."
    end

  end
end
