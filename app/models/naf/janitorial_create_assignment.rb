module Naf
  class JanitorialCreateAssignment < JanitorialAssignment
    def do_janitorial_work(target_model)
      target_model.create_new_partitions
    end
  end
end
