class MoveTabsColumnFromHistoricalJobsToRunningJobs < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE #{Naf.schema_name}.historical_jobs DROP COLUMN tags;
      ALTER TABLE #{Naf.schema_name}.running_jobs ADD COLUMN tags text[];
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE #{Naf.schema_name}.historical_jobs ADD COLUMN tags text[];
      ALTER TABLE #{Naf.schema_name}.running_jobs DROP COLUMN tags;
    SQL
  end
end
