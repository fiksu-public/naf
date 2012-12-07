module Logical
  module Naf
    module JobStatuses
      class Finished

        def self.all(conditions)
          <<-SQL
            (SELECT j.*, null AS "job_id"
              FROM "#{::Naf.schema_name}"."jobs" AS j
              WHERE j.finished_at is not null or j.request_to_terminate = true
              #{conditions}
              ORDER BY finished_at desc)
          SQL
        end

      end
    end
  end
end