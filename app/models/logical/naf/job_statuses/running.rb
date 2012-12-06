module Logical
  module Naf
    module JobStatuses
      class Running

        def self.all(status = :running, conditions, values)
          if status == :queued
            order = "created_at"
            direction = "desc"
          else
            order = "started_at"
            direction = "desc"
          end
          sql = <<-SQL
            SELECT j.*
              FROM "#{::Naf.schema_name}"."jobs" AS j
              WHERE j.started_at is not null and j.finished_at is null and j.request_to_terminate = false
              #{conditions}
              ORDER BY #{order} #{direction}
              LIMIT :limit OFFSET :offset
          SQL

          ::Naf::Job.find_by_sql([sql, values])
        end

      end
    end
  end
end