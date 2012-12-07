module Logical
  module Naf
    module JobStatuses
      class Running

        def self.all(status = :running, conditions)
          if status == :queued
            order = "created_at"
            direction = "desc"
          else
            order = "started_at"
            direction = "desc"
          end
          <<-SQL
            (SELECT j.*, null AS "job_id"
              FROM "#{::Naf.schema_name}"."jobs" AS j
              WHERE j.started_at is not null and j.finished_at is null and j.request_to_terminate = false
              #{conditions}
              ORDER BY #{order} #{direction})
          SQL
        end

      end
    end
  end
end