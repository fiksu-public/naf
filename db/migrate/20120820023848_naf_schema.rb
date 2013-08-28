class NafSchema < ActiveRecord::Migration

  def up
    # Define a schema_name, the scheduling tables fall under:
    schema_name = Naf.schema_name

    # affinities
    #  names: normal, canary, perennial
    #  location: ip address
    #  application/release on machine: application-release-number
    execute <<-SQL

      do LANGUAGE plpgsql $$
        begin
          if (SELECT count(*) FROM pg_namespace WHERE nspname !~ '^pg_.*' AND nspname NOT IN ('information_schema') AND nspname = '#{schema_name}') > 0 THEN
            raise notice 'Skipping creation of schema: #{schema_name}, already exists';
          else
            raise notice 'Creating new schema #{schema_name}';
            create schema #{schema_name};
          end if;
        end;
      $$;

      create table #{schema_name}.affinity_classifications
      (
          id                             serial not null primary key,
          created_at                     timestamp not null default now(),
          updated_at                     timestamp,
          affinity_classification_name   text not null unique
      );
      insert into #{schema_name}.affinity_classifications (affinity_classification_name) values
        ('location'), ('purpose'), ('application'), ('weight'), ('machine');
      create table #{schema_name}.affinities
      (
          id                            serial not null primary key,
          created_at                    timestamp not null default now(),
          updated_at                    timestamp,
          selectable                    boolean not null default true,
          affinity_classification_id    integer not null references #{schema_name}.affinity_classifications,
          affinity_name                 text not null,
          affinity_short_name           text unique check ( affinity_short_name ~ '^[a-zA-Z_][a-zA-Z0-9_]*$' ),
          affinity_note                 text null,
          unique (affinity_classification_id, affinity_name)
      );
      insert into #{schema_name}.affinities (affinity_classification_id, affinity_name) values
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'purpose'), 'normal'),
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'purpose'), 'canary'),
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'purpose'), 'perennial'),
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'weight'), 'memory'),
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'weight'), 'cpus');
      create table #{schema_name}.machines
      (
          id                             serial not null primary key,
          created_at                     timestamp not null default now(),
          updated_at                     timestamp,
          server_address                 inet not null unique,
          server_name                    text,
          short_name                     text unique check ( short_name ~ '^[a-zA-Z_][a-zA-Z0-9_]*$' ),
          server_note                    text,
          enabled                        boolean not null default true,
          thread_pool_size               integer not null default 5,
          last_checked_schedules_at      timestamp null,
          last_seen_alive_at             timestamp null,
          marked_down                    boolean not null default false,
          marked_down_by_machine_id      integer null references #{schema_name}.machines,
          marked_down_at                 timestamp null,
          log_level                      text null,
          deleted                        boolean not null default false check (deleted = false OR enabled = false)
      );
      create table #{schema_name}.machine_affinity_slots
      (
          id                                      serial not null primary key,
          created_at                              timestamp not null default now(),
          machine_id			                        integer not null references #{schema_name}.machines,
          affinity_id                        	    integer not null references #{schema_name}.affinities,
          affinity_parameter                      numeric null,
          required                                boolean not null default false,
          unique (machine_id, affinity_id)
      );
      create table #{schema_name}.machine_runners
      (
          id                    serial not null primary key,
          created_at            timestamp not null default now(),
          machine_id            integer not null references naf.machines,
          runner_cwd            text not null,
          unique (machine_id, runner_cwd)
      );
      create table #{schema_name}.machine_runner_invocations
      (
          id                    serial not null primary key,
          created_at            timestamp not null default now(),
          updated_at            timestamp,
          machine_runner_id     integer not null references naf.machine_runners,
          pid                   integer not null,
          is_running            boolean not null default true,
          wind_down             boolean not null default false,
          commit_information    text null,
          branch_name           text null,
          repository_name       text null,
          deployment_tag        text null
      );
      create table #{schema_name}.application_types
      (
          id                  serial not null primary key,
          created_at          timestamp not null default now(),
          updated_at          timestamp,
          enabled             boolean not null default true,
          script_type_name    text unique not null,
          description         text,
          invocation_method   text not null
      );
      insert into #{schema_name}.application_types (script_type_name, description, invocation_method) values
        ('rails', 'ruby on rails NAF application', 'rails_invocator'),
        ('bash command', 'bash command', 'bash_command_invocator'),
        ('bash script', 'bash script', 'bash_script_invocator'),
        ('ruby', 'ruby script', 'ruby_script_invocator');
      create table #{schema_name}.applications
      (
          id                              serial not null primary key,
          created_at                      timestamp not null default now(),
          updated_at                      timestamp,
          deleted                         boolean not null default false,
          application_type_id	            integer not null references #{schema_name}.application_types,
          command                         text not null,
          title                           text not null,
          short_name                      text null unique check ( short_name ~ '^[a-zA-Z_][a-zA-Z0-9_]*$' ),
          log_level                       text null
      );
      insert into #{schema_name}.applications (application_type_id, command, title) values
        (
          (select id from #{schema_name}.application_types where script_type_name = 'rails'),
          '::Process::Naf::Janitor.run',
          'Database Janitorial Work'
        );
      create table #{schema_name}.application_run_group_restrictions
      (
          id                                        serial not null primary key,
          created_at                                timestamp not null default now(),
          application_run_group_restriction_name    text unique not null
      );
      insert into #{schema_name}.application_run_group_restrictions (application_run_group_restriction_name) values
         ('no limit'), ('limited per machine'), ('limited per all machines');
      create table #{schema_name}.application_schedules
      (
          id                                       serial not null primary key,
          created_at                               timestamp not null default now(),
          updated_at                               timestamp,
          enabled                                  boolean not null default true,
          visible                                  boolean not null default true,
          application_id                           integer unique not null references #{schema_name}.applications,
          application_run_group_restriction_id     integer not null references #{schema_name}.application_run_group_restrictions,
          application_run_group_name               text null,
          application_run_group_limit              integer null check (application_run_group_limit >= 1 or application_run_group_limit is null),
          run_start_minute                         integer null check (run_start_minute >= 0 and run_start_minute < (24 * 60)),
          run_interval                             integer null check (run_interval >= 0),
          priority                                 integer not null default 0,
          enqueue_backlogs                         boolean not null default false,
          check (visible = true OR enabled = false),
          check (run_start_minute is null OR run_interval is null)
      );
      insert into #{schema_name}.application_schedules
        (application_id, application_run_group_restriction_id, application_run_group_name, application_run_group_limit, run_start_minute, run_interval) values
        (
          (select id from #{schema_name}.applications where command = '::Process::Naf::Janitor.run'),
          (select id from #{schema_name}.application_run_group_restrictions where application_run_group_restriction_name = 'limited per all machines'),
          '::Process::Naf::Janitor.run',
          1,
          5,
          null
        );
      create unique index applications_have_one_schedule_udx on #{schema_name}.application_schedules (application_id) where enabled = true;
      create table #{schema_name}.application_schedule_affinity_tabs
      (
          id                                 serial not null primary key,
          created_at                         timestamp not null default now(),
          application_schedule_id 	         integer not null references #{schema_name}.application_schedules,
          affinity_id           	           integer not null references #{schema_name}.affinities,
          affinity_parameter                 numeric null,
          UNIQUE (application_schedule_id, affinity_id)
      );
      create table #{schema_name}.application_schedule_prerequisites
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          application_schedule_id                integer not null references #{schema_name}.application_schedules,
          prerequisite_application_schedule_id   integer not null references #{schema_name}.application_schedules,
          UNIQUE (application_schedule_id, prerequisite_application_schedule_id),
          CHECK (application_schedule_id <> prerequisite_application_schedule_id)
      );
      create table #{schema_name}.historical_jobs
      (
          id                                     bigserial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,

          application_id                         integer null references #{schema_name}.applications,
          application_type_id                    integer not null references #{schema_name}.application_types,
          command                                text not null,

          application_run_group_restriction_id   integer not null references #{schema_name}.application_run_group_restrictions,
          application_run_group_name             text null,
          application_run_group_limit            integer null default 1,

          priority                               integer not null default 0,

          started_on_machine_id                  integer null references #{schema_name}.machines,

          failed_to_start                        boolean null,
          started_at                             timestamp null,
          pid                                    integer null,
          finished_at                            timestamp null,
          exit_status                            integer null,
          termination_signal                     integer null,

          state                                  text null,

          request_to_terminate                   boolean not null default false,

          marked_dead_by_machine_id              integer null references #{schema_name}.machines,
          marked_dead_at                         timestamp null,

          log_level                              text null,
          tags                                   text[],
          machine_runner_invocation_id                      integer null references #{schema_name}.machine_runner_invocations
      );
      create table #{schema_name}.historical_job_prerequisites
      (
          id                                     bigserial not null primary key,
          created_at                             timestamp not null default now(),
          historical_job_id                      bigint not null, -- references #{schema_name}.historical_jobs,
          prerequisite_historical_job_id         bigint not null, -- references #{schema_name}.historical_jobs,
          UNIQUE (historical_job_id, prerequisite_historical_job_id),
          CHECK (historical_job_id <> prerequisite_historical_job_id)
      );
      create table #{schema_name}.historical_job_affinity_tabs
      (
          id                                     bigserial not null primary key,
          created_at                             timestamp not null default now(),
          historical_job_id                      bigint not null, -- references #{schema_name}.historical_jobs,
          affinity_id                            bigint not null references #{schema_name}.affinities,
          affinity_parameter                     numeric null,
          UNIQUE (historical_job_id, affinity_id)
      );
      create table #{schema_name}.queued_jobs
      (
          id                                     bigint not null primary key, -- references #{schema_name}.historical_jobs
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,

          application_id                         integer null references #{schema_name}.applications,
          application_type_id                    integer not null references #{schema_name}.application_types,
          command                                text not null,

          application_run_group_restriction_id   integer not null references #{schema_name}.application_run_group_restrictions,
          application_run_group_name             text null,
          application_run_group_limit            integer null default 1,

          priority                               integer not null default 0
      );
      create table #{schema_name}.running_jobs
      (
          id                                     bigint not null primary key, -- references #{schema_name}.historical_jobs
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,

          application_id                         integer null references #{schema_name}.applications,
          application_type_id                    integer not null references #{schema_name}.application_types,
          command                                text not null,

          application_run_group_restriction_id   integer not null references #{schema_name}.application_run_group_restrictions,
          application_run_group_name             text null,
          application_run_group_limit            integer null default 1,

          started_on_machine_id                  integer not null references #{schema_name}.machines,

          started_at                             timestamp null,
          pid                                    integer null,

          request_to_terminate                   boolean not null default false,

          marked_dead_by_machine_id              integer null references #{schema_name}.machines,
          marked_dead_at                         timestamp null,

          log_level                              text null
      );
      create table #{schema_name}.janitorial_assignments
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          type                                   text not null,
          enabled                                boolean not null default true,
          deleted                                boolean not null default false,
          model_name                             text not null,  -- ::Naf::HistoricalJob
          assignment_order                       integer not null default 0,
          check (deleted = false OR enabled = false)
      );
      create table #{schema_name}.logger_styles
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          name                                   text not null unique,
          note                                   text null
      );
      create table #{schema_name}.logger_names
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          name                                   text not null unique
      );
      create table #{schema_name}.logger_levels
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          level                                  text not null unique
      );
      insert into #{schema_name}.logger_levels (level) values
        ('ALL'),
        ('DEBUG'),
        ('DEBUG_FINE'),
        ('DEBUG_MEDIUM'),
        ('DEBUG_GROSS'),
        ('DETAIL'),
        ('INFO'),
        ('WARN'),
        ('ALARM'),
        ('ERROR'),
        ('FATAL'),
        ('OFF');
      create table #{schema_name}.logger_style_names
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          logger_style_id                        integer not null references #{schema_name}.logger_styles,
          logger_name_id                         integer not null references #{schema_name}.logger_names,
          logger_level_id                        integer not null references #{schema_name}.logger_levels,
          UNIQUE(logger_style_id, logger_name_id)
      );
      insert into #{schema_name}.janitorial_assignments (type, assignment_order, model_name) values
        ('Naf::JanitorialCreateAssignment', 500, '::Naf::HistoricalJob'),
        ('Naf::JanitorialDropAssignment',   500, '::Naf::HistoricalJob'),
        ('Naf::JanitorialCreateAssignment', 125, '::Naf::HistoricalJobPrerequisite'),
        ('Naf::JanitorialDropAssignment',   125, '::Naf::HistoricalJobPrerequisite'),
        ('Naf::JanitorialCreateAssignment', 250, '::Naf::HistoricalJobAffinityTab'),
        ('Naf::JanitorialDropAssignment',   250, '::Naf::HistoricalJobAffinityTab');

      set search_path = 'public';

    SQL
  end

  def down
    schema_name = Naf.schema_name
    execute <<-SQL
      drop table #{schema_name}.janitorial_assignments cascade;
      drop table #{schema_name}.historical_job_affinity_tabs cascade;
      drop table #{schema_name}.historical_job_prerequisites cascade;
      drop table #{schema_name}.historical_jobs cascade;
      drop table #{schema_name}.running_jobs cascade;
      drop table #{schema_name}.queued_jobs cascade;
      drop table #{schema_name}.affinities cascade;
      drop table #{schema_name}.affinity_classifications cascade;
      drop table #{schema_name}.machines cascade;
      drop table #{schema_name}.machine_runner_invocations cascade;
      drop table #{schema_name}.machine_runners cascade;
      drop table #{schema_name}.machine_affinity_slots cascade;
      drop table #{schema_name}.applications cascade;
      drop table #{schema_name}.application_types cascade;
      drop table #{schema_name}.application_run_group_restrictions cascade;
      drop table #{schema_name}.application_schedule_prerequisites cascade;
      drop table #{schema_name}.application_schedules cascade;
      drop table #{schema_name}.application_schedule_affinity_tabs cascade;
      drop table #{schema_name}.logger_levels cascade;
      drop table #{schema_name}.logger_names cascade;
      drop table #{schema_name}.logger_styles cascade;
      drop table #{schema_name}.logger_style_names cascade;
    SQL

    if schema_name != "public"
      execute <<-SQL
        do LANGUAGE plpgsql $$
          begin
            if (SELECT COUNT(*) FROM pg_tables WHERE schemaname = '#{schema_name}') > 0 THEN
              raise notice 'Skipping drop of schema:: #{schema_name}, there are still other tables under it!';
            else
              raise notice 'Dropping schema #{schema_name}';
              drop schema #{schema_name} cascade;
            end if;
          end;
        $$;
      SQL
    end

    schemas = execute <<-SQL
      SELECT 'drop schema ' || nspname ||' cascade;'
      FROM pg_namespace
      WHERE nspname = 'naf_historical_job_affinity_tabs_partitions' OR
        nspname = 'naf_historical_job_prerequisites_partitions' OR
        nspname = 'naf_historical_jobs_partitions';
    SQL

    schemas.values.each do |schema|
      execute <<-SQL
        #{schema.first}
      SQL
    end

  end
end
