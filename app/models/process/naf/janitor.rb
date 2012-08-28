module Process::Naf
  class Janitor < ::Process::Naf::Application

    def work
      logger.info "Janitor started -- let's see what there is to do."
      ::Naf::JanitorialAssignment.enabled.each do |assignment|
        logger.info "assignment: #{assignment.model_name} START"
        target_model = assignment.target_model
        if target_model.nil?
          logger.alarm "failed to instantiate target model: #{assignment.model_name}"
          next
        end
        if assignment.janitorial_creates_enabled
          begin
            logger.info "creating new partitions: #{assignment.model_name}"
            target_model.create_new_partitions
          rescue StandardError => e
            logger.alarm "failed to create new partitions for model: #{assignment.model_name}, #{e.message}"
          end
        end
        if assignment.janitorial_archives_enabled
          begin
            logger.info "creating new partitions: #{assignment.model_name}"
            target_model.archive_old_partitions
          rescue StandardError => e
            logger.alarm "failed to archive old partitions for model: #{assignment.model_name}, #{e.message}"
          end
        end
        if assignment.janitorial_drops_enabled
          begin
            logger.info "creating new partitions: #{assignment.model_name}"
            target_model.drop_old_partitions
          rescue StandardError => e
            logger.alarm "failed to drop old partitions for model: #{assignment.model_name}, #{e.message}"
          end
        end
        logger.info "assignment: #{assignment.model_name} DONE"
      end
    end
  end
end
