module Process::Naf
  class Janitor < ::Process::Naf::Application
    opt :no_writes, "don't modify database"
    opt :list_assignments, "list models that would be processed (and exit without processing)", :short => :L
    opt :all, "process all models", :short => :a, :var => :assignments, :set => :all
    opt :all_enabled, "process all enabled models", :short => :E, :var => :assignments, :set => :all_enabled, :default => :all_enabled
    opt :assignment, "process specific assignment(s)", :short => :c, :var => :assignments, :type => :ints

    def assignments_to_process
      if @assignment == :all
        return ::Naf::JanitorialAssignment.all
      elsif @assignment == :all_enabled
        return ::Naf::JanitorialAssignment.where('enabled')
      else
        return [*::Naf::JanitorialAssignment.find(@assignment)]
      end
    end

    def post_command_line_parsing
      if @list_assignments
        puts self.class.columnized(assignments_to_process.map{|a| [a.id.to_s, a.model_name]}.join("\n"))
        exit 0
      end
      super
    end

    def work
      logger.info "Janitor started -- let's see what there is to do."
      assignments_to_process.each do |assignment|
        logger.info "assignment: #{assignment.model_name} START"
        target_model = assignment.target_model
        if target_model.nil?
          logger.alarm "failed to instantiate target model: #{assignment.model_name}"
          next
        end
        if assignment.janitorial_creates_enabled
          begin
            logger.info "creating new partitions: #{assignment.model_name}"
            target_model.create_new_partitions unless @no_writes
          rescue StandardError => e
            logger.alarm "failed to create new partitions for model: #{assignment.model_name}, #{e.message}"
          end
        end
        if assignment.janitorial_archives_enabled
          begin
            logger.info "creating new partitions: #{assignment.model_name}"
            target_model.archive_old_partitions unless @no_writes
          rescue StandardError => e
            logger.alarm "failed to archive old partitions for model: #{assignment.model_name}, #{e.message}"
          end
        end
        if assignment.janitorial_drops_enabled
          begin
            logger.info "creating new partitions: #{assignment.model_name}"
            target_model.drop_old_partitions unless @no_writes
          rescue StandardError => e
            logger.alarm "failed to drop old partitions for model: #{assignment.model_name}, #{e.message}"
          end
        end
        logger.info "assignment: #{assignment.model_name} DONE"
      end
    end
  end
end
