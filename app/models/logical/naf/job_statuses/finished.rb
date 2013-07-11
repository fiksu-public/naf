module Logical
  module Naf
    module JobStatuses
      class Finished

        def self.all(conditions)
          <<-SQL
            (SELECT j.*, null AS "historical_job_id"
              FROM "#{::Naf.schema_name}"."historical_jobs" AS j
              WHERE j.finished_at is not null or j.request_to_terminate = true
              #{conditions}
              ORDER BY finished_at DESC NULLS LAST)
          SQL
        end

      end
    end
  end
end