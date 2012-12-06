module Logical
  module Naf
    module JobStatuses
      class Errored

        def self.all(conditions, values)

          sql = <<-SQL
            SELECT j.*
              FROM "#{::Naf.schema_name}"."jobs" AS j
              WHERE j.finished_at is NOT NULL AND j.exit_status > 0 OR j.request_to_terminate = true
              #{conditions}
              ORDER BY finished_at desc
              LIMIT :limit OFFSET :offset
          SQL

          ::Naf::Job.find_by_sql([sql, values])
        end

      end
    end
  end
end