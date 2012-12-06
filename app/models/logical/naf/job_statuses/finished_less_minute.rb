module Logical
  module Naf
    module JobStatuses
      class FinishedLessMinute

        def self.all(conditions, values)
          sql = <<-SQL
            SELECT j.*
              FROM "#{::Naf.schema_name}"."jobs" AS j
              WHERE j.finished_at > '#{Time.zone.now - 1.minute}'
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