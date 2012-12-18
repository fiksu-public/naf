module Logical
  module Naf
    module JobStatuses
      class Waiting

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
               j.request_to_terminate = false AND
               jp.job_id IS NOT NULL AND
               j.started_at IS NULL AND
               EXISTS
               (
                SELECT
                  1
                FROM
                 #{::Naf::Job.table_name}
                JOIN #{::Naf::JobPrerequisite.table_name} ON
                 #{::Naf::Job.table_name}.id = #{::Naf::JobPrerequisite.table_name}.prerequisite_job_id
                WHERE
                 #{::Naf::JobPrerequisite.table_name}.job_id = jp.job_id AND
                 #{::Naf::Job.table_name}.finished_at IS NULL
               )
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