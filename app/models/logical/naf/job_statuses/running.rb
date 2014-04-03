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
            (
              SELECT
                j.*, null AS "historical_job_id"
              FROM
                "#{::Naf.schema_name}"."historical_jobs" AS j
              WHERE
                j.started_at IS NOT NULL AND
                j.finished_at IS NULL AND
                j.request_to_terminate = false
              #{conditions}
              ORDER BY
                #{order} #{direction}
            )
          SQL
        end

      end
    end
  end
end