module Naf
  class JanitorialDropAssignment < JanitorialAssignment
    def do_janitorial_work(target_model)
      target_model.drop_old_partitions
    end
  end
end
