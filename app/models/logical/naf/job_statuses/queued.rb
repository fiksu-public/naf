module Logical
  module Naf
    module JobStatuses
      class Queued

        def self.all(conditions, values)
          sql = <<-SQL
            SELECT DISTINCT j.*, jp."job_id"
              FROM "#{::Naf.schema_name}"."jobs" AS j
              LEFT JOIN  "#{::Naf.schema_name}"."job_prerequisites" AS jp
              ON j."id" = jp."job_id"
              WHERE j.finished_at is null AND j.request_to_terminate = false AND jp.job_id is null
              AND j.started_at is null
              #{conditions}
              ORDER BY created_at desc
              LIMIT :limit OFFSET :offset
          SQL

          ::Naf::Job.find_by_sql([sql, values])
        end

      end
    end
  end
end