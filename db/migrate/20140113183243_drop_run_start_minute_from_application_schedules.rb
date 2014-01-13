class DropRunStartMinuteFromApplicationSchedules < ActiveRecord::Migration
  def up
    execute <<-SQL
			ALTER TABLE #{Naf.schema_name}.application_schedules DROP COLUMN run_start_minute;
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval SET NOT NULL;
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval_style_id SET NOT NULL;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE #{Naf.schema_name}.application_schedules ADD COLUMN run_start_minute INTEGER NULL
      	CHECK (run_start_minute >= 0 and run_start_minute < (24 * 60));
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval DROP NOT NULL;
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval_style_id DROP NOT NULL;
    SQL
  end
end
