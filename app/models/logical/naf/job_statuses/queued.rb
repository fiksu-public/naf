module Logical
  module Naf
    module JobStatuses
      class Queued

        def self.all(conditions)
          <<-SQL
            (
             SELECT DISTINCT
               j.*,
               jp.job_id
              FROM
               #{::Naf::Job.table_name} AS j
              LEFT JOIN #{::Naf::JobPrerequisite.table_name} AS jp ON
               j.id = jp.job_id
              WHERE
               j.finished_at IS NULL AND
               j.request_to_terminate = FALSE AND
               jp.job_id IS NULL AND
               j.started_at IS NULL
               #{conditions}
              ORDER BY
               created_at DESC
            )
          SQL
        end

      end
    end
  end
end

