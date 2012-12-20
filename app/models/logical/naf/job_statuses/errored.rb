module Logical
  module Naf
    module JobStatuses
      class Errored

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
                j.finished_at IS NOT NULL AND
                j.exit_status > 0 OR
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