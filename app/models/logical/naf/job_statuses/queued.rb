module Logical
  module Naf
    module JobStatuses
      class Queued

        def self.all(conditions)
          <<-SQL
            (
              SELECT DISTINCT
                j.*, jp."historical_job_id"
              FROM
                "#{::Naf.schema_name}"."historical_jobs" AS j
              LEFT JOIN
                "#{::Naf.schema_name}"."historical_job_prerequisites" AS jp
                ON j."id" = jp."historical_job_id"
              WHERE
                j.finished_at IS NULL AND
                j.request_to_terminate = false AND
                jp.historical_job_id IS NULL AND
                j.started_at IS NULL
              #{conditions}
              ORDER BY
                created_at desc
            )
          SQL
        end

      end
    end
  end
end

