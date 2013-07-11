module Logical
  module Naf
    module JobStatuses
      class Waiting

        def self.all(conditions)
          <<-SQL
            (SELECT DISTINCT j.*, jp."historical_job_id"
              FROM "#{::Naf.schema_name}"."historical_jobs" AS j
              LEFT JOIN  "#{::Naf.schema_name}"."historical_job_prerequisites" AS jp
              ON j."id" = jp."historical_job_id"
              WHERE j.finished_at is null AND j.request_to_terminate = false AND jp.historical_job_id is not null
              AND j.started_at is null AND EXISTS (
                  SELECT 1 FROM "#{::Naf.schema_name}"."historical_jobs"
                  JOIN "#{::Naf.schema_name}"."historical_job_prerequisites" ON
                  "#{::Naf.schema_name}"."historical_jobs"."id" = "#{::Naf.schema_name}"."historical_job_prerequisites"."prerequisite_historical_job_id"
                  WHERE "#{::Naf.schema_name}"."historical_job_prerequisites"."historical_job_id" = jp."historical_job_id"
                  AND "#{::Naf.schema_name}"."historical_jobs"."started_at" is null
              )
              #{conditions}
              ORDER BY created_at desc)
          SQL
        end

      end
    end
  end
end