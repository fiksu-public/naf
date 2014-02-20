class AddRunIntervalStylesTable < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE #{Naf.schema_name}.run_interval_styles
      (
        id              SERIAL NOT NULL PRIMARY KEY,
        created_at      TIMESTAMP NOT NULL default now(),
        name            TEXT NOT NULL
      );

      INSERT INTO #{Naf.schema_name}.run_interval_styles (name)
        VALUES ('at beginning of day'), ('at beginning of hour'), ('after previous run'), ('keep running');

      ALTER TABLE #{Naf.schema_name}.application_schedules
        ADD COLUMN run_interval_style_id INTEGER NULL REFERENCES #{Naf.schema_name}.run_interval_styles;
      ALTER TABLE #{Naf.schema_name}.application_schedules ADD COLUMN application_run_group_quantum INTEGER NULL;
      ALTER TABLE #{Naf.schema_name}.application_schedules
        DROP CONSTRAINT application_schedules_check1;
      DROP INDEX #{Naf.schema_name}.applications_have_one_schedule_udx ;
      ALTER TABLE #{Naf.schema_name}.application_schedules
        DROP CONSTRAINT application_schedules_application_id_key;

      ALTER TABLE #{Naf.schema_name}.historical_jobs
        ADD COLUMN application_schedule_id INTEGER NULL REFERENCES #{Naf.schema_name}.application_schedules;
      ALTER TABLE #{Naf.schema_name}.running_jobs
        ADD COLUMN application_schedule_id INTEGER NULL REFERENCES #{Naf.schema_name}.application_schedules;
      ALTER TABLE #{Naf.schema_name}.queued_jobs
        ADD COLUMN application_schedule_id INTEGER NULL REFERENCES #{Naf.schema_name}.application_schedules;

      DELETE FROM #{Naf.schema_name}.application_schedules
        WHERE application_run_group_name = '::Process::Naf::Janitor.run';
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE #{Naf.schema_name}.queued_jobs DROP COLUMN application_schedule_id;
      ALTER TABLE #{Naf.schema_name}.running_jobs DROP COLUMN application_schedule_id;
      ALTER TABLE #{Naf.schema_name}.historical_jobs DROP COLUMN application_schedule_id;

      ALTER TABLE #{Naf.schema_name}.application_schedules
        ADD CONSTRAINT application_schedules_application_id_key UNIQUE (application_id);
      CREATE UNIQUE INDEX applications_have_one_schedule_udx
        ON #{Naf.schema_name}.application_schedules (application_id) WHERE enabled = true;
      ALTER TABLE #{Naf.schema_name}.application_schedules ADD CONSTRAINT application_schedules_check1
        CHECK (run_start_minute IS NULL OR run_interval IS NULL);
      ALTER TABLE #{Naf.schema_name}.application_schedules DROP COLUMN application_run_group_quantum;
      ALTER TABLE #{Naf.schema_name}.application_schedules DROP COLUMN run_interval_style_id;
      DROP TABLE #{Naf.schema_name}.run_interval_styles;

      INSERT INTO #{Naf.schema_name}.application_schedules (application_id, application_run_group_restriction_id,
        application_run_group_name, application_run_group_limit, run_start_minute, run_interval) VALUES
        (
          (SELECT id FROM #{Naf.schema_name}.applications where command = '::Process::Naf::Janitor.run'),
          (SELECT id FROM #{Naf.schema_name}.application_run_group_restrictions
            WHERE application_run_group_restriction_name = 'limited per all machines'),
          '::Process::Naf::Janitor.run',
          1,
          5,
          NULL
        );
    SQL
  end
end
