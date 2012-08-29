module Process::Naf
  class Janitor < ::Process::Naf::Application
    ASSIGNMENTS = {
      :creates => ::Naf::JanitorialCreateAssignment,
      :archives => ::Naf::JanitorialArchiveAssignment,
      :drops => ::Naf::JanitorialDropAssignment
    }
    ASSIGNMENT_TYPES = ASSIGNMENTS.keys

    opt :no_writes, "don't modify database"
    opt :list_assignments, "list models that would be processed (and exit without processing)", :short => :L
    opt :all, "process all models", :short => :a, :var => :assignments, :set => :all
    opt :all_enabled, "process all enabled models", :short => :E, :var => :assignments, :set => :all_enabled, :default => :all_enabled
    opt :assignment, "process specific assignment(s)", :short => :c, :var => :assignments, :type => :ints
    opt :assignment_type, "process specific assignment types(s)", :short => :t, :var => :assignment_types, :type => :symbols, :choices => ASSIGNMENT_TYPES, :default => ASSIGNMENT_TYPES
    opt :all_types, "process all assignment types", :short => :A, :var => :assignment_types, :set => ASSIGNMENT_TYPES

    def assignments_to_process(assignment_type = ::Naf::JanitorialCreateAssignment)
      if @assignment == :all
        return assignment_type.all.order('type,assignment_order')
      elsif @assignment == :all_enabled
        return assignment_type.where('enabled').order('type,assignment_order')
      else
        return [*assignment_type.find(@assignment).order('type,assignment_order')]
      end
    end

    def post_command_line_parsing
      if @list_assignments
        puts self.class.columnized(assignments_to_process.map{|a| [a.id.to_s, a.type.to_s, a.assignment_order.to_s, a.model_name]}.join("\n"))
        exit 0
      end
      super
    end

    def work
      logger.info "Janitor STARTED -- let's see what there is to do."

      # assignment types are handled in this order
      [:creates, :archives, :drops].each do |assignment_type_name|
        unless @assignment_type.include? assignment_type_name
          next
        end
        assignment_type_processor = ASSIGNMENTS[assignment_type_name]
        assignments_to_process(assignment_type_processor).each do |assignment|
          logger.info "#{assignment_type_processor}: #{assignment.model_name} START"
          target_model = assignment.target_model
          if target_model.nil?
            logger.alarm "#{assignment_type_processor}: failed to instantiate target model: #{assignment.model_name}"
            next
          end
          begin
            target_model.create_new_partitions unless @no_writes
          rescue StandardError => e
            logger.alarm "failed to use #{assignment_type_processor} for partitions model: #{assignment.model_name}, #{e.message}"
          end
          logger.info "#{assignment_type_processor}: #{assignment.model_name} DONE"
        end
      end

      logger.info "janitor DONE"
    end
  end
end
