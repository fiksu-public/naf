module Logical
  module Naf
    module JobStatuses
      class Terminated

        def self.all(conditions)
          <<-SQL
          (
            SELECT
              hj.*, NULL AS "historical_job_id"
            FROM
              "#{::Naf.schema_name}"."historical_jobs" AS hj
            WHERE
              hj.request_to_terminate IS TRUE AND hj.finished_at IS NULL
              #{conditions}
            ORDER BY
              finished_at DESC NULLS LAST
          )
          SQL
        end

      end
    end
  end
end