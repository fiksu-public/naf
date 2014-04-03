class DropRunStartMinuteFromApplicationSchedules < ActiveRecord::Migration
  def up
    execute <<-SQL
			ALTER TABLE #{Naf.schema_name}.application_schedules DROP COLUMN run_start_minute;
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval SET NOT NULL;
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval_style_id SET NOT NULL;

      INSERT INTO #{Naf.schema_name}.application_schedules (application_id, application_run_group_restriction_id,
        application_run_group_name, application_run_group_limit, run_interval, run_interval_style_id) VALUES
        (
          (SELECT id FROM #{Naf.schema_name}.applications where command = '::Process::Naf::Janitor.run'),
          (SELECT id FROM #{Naf.schema_name}.application_run_group_restrictions
            WHERE application_run_group_restriction_name = 'limited per all machines'),
          '::Process::Naf::Janitor.run',
          1,
          5,
          1
        );
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE #{Naf.schema_name}.application_schedules ADD COLUMN run_start_minute INTEGER NULL
      	CHECK (run_start_minute >= 0 and run_start_minute < (24 * 60));
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval DROP NOT NULL;
			ALTER TABLE #{Naf.schema_name}.application_schedules ALTER COLUMN run_interval_style_id DROP NOT NULL;

      DELETE FROM #{Naf.schema_name}.application_schedules
        WHERE application_run_group_name = '::Process::Naf::Janitor.run';
    SQL
  end
end
