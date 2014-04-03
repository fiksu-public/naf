module Logical
  module Naf
    module JobStatuses
      class Errored

        def self.all(conditions)
          <<-SQL
            (
              SELECT
                j.*, null AS "historical_job_id"
              FROM
                "#{::Naf.schema_name}"."historical_jobs" AS j
              WHERE
                j.finished_at IS NOT NULL AND
                (j.exit_status > 0 OR
                j.request_to_terminate = true)
                #{conditions}
              ORDER BY
                finished_at desc
            )
          SQL
        end

      end
    end
  end
end
