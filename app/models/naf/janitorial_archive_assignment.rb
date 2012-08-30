module Naf
  class JanitorialArchiveAssignment < JanitorialAssignment
    def do_janitorial_work(target_model)
      target_model.archive_old_partitions
    end
  end
end
