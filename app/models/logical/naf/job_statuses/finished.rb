module Logical
  module Naf
    module JobStatuses
      class Finished

        def self.all(conditions)
          <<-SQL
            (
             SELECT
               j.*,
               NULL AS job_id
              FROM
               #{::Naf::Job.table_name} AS j
              WHERE
               (
                j.finished_at IS NOT NULL OR
                j.request_to_terminate = true
               )
               #{conditions}
              ORDER BY
               finished_at DESC
            )
          SQL
        end

      end
    end
  end
end