# This migration comes from naf (originally 20120820023848)
class NafSchema < ActiveRecord::Migration

  def up
    # Define a schema_name, the scheduling tables fall under:
    schema_name = Naf::JOB_SYSTEM_SCHEMA_NAME

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
        ('location'), ('purpose'), ('application');
      create table #{schema_name}.affinities
      (
          id                            serial not null primary key,
          created_at                    timestamp not null default now(),
          updated_at                    timestamp,
          selectable                    boolean not null default true,
          affinity_classification_id    integer not null references #{schema_name}.affinity_classifications,
          affinity_name                 text not null,
          unique (affinity_classification_id, affinity_name)
      );
      insert into #{schema_name}.affinities (affinity_classification_id, affinity_name) values
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'purpose'), 'normal'),
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'purpose'), 'canary'),
         ((select id from #{schema_name}.affinity_classifications where affinity_classification_name = 'purpose'), 'perennial');
      create table #{schema_name}.machines
      (
          id                         serial not null primary key,
          created_at                 timestamp not null default now(),
          updated_at                 timestamp,
          server_address             inet not null unique,
          server_name                text,
          server_note                text,
          enabled                    boolean not null default true,
          thread_pool_size           integer not null default 5,
          last_checked_schedules_at  timestamp null,
          last_seen_alive_at         timestamp null,
          log_level                  text null
      );
      create table #{schema_name}.machine_affinity_slots
      (
          id                                        serial not null primary key,
          created_at                                timestamp not null default now(),
          machine_id			            integer not null references #{schema_name}.machines,
          affinity_id                        	    integer not null references #{schema_name}.affinities,
          required                                  boolean not null default false,
          unique (machine_id, affinity_id)
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
          application_type_id	          integer not null references #{schema_name}.application_types,
          command                         text not null,
          title                           text not null,
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
         ('no restrictions'), ('one at a time'), ('one per machine');
      create table #{schema_name}.application_schedules
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          enabled                                boolean not null default true,
          visible                                boolean not null default true,
          application_id                         integer unique not null references #{schema_name}.applications,
          application_run_group_restriction_id   integer not null references #{schema_name}.application_run_group_restrictions,
          application_run_group_name             text null,
          run_start_minute                       integer null check (run_start_minute >= 0 and run_start_minute < (24 * 60)),
          run_interval                           integer null check (run_interval > 0),
          priority                               integer not null default 0,
          check (visible = true OR enabled = false),
          check (run_start_minute is not null OR run_interval is not null),
          check (run_start_minute is null OR run_interval is null)
      );
      insert into #{schema_name}.application_schedules
        (application_id, application_run_group_restriction_id, application_run_group_name, run_start_minute, run_interval) values
        (
          (select id from #{schema_name}.applications where command = '::Process::Naf::Janitor.run'),
          (select id from #{schema_name}.application_run_group_restrictions where application_run_group_restriction_name = 'one at a time'),
          '::Process::Naf::Janitor.run',
          5,
          null
        );
      create unique index applications_have_one_schedule_udx on #{schema_name}.application_schedules (application_id) where enabled = true;
      create table #{schema_name}.application_schedule_affinity_tabs
      (
          id                                 serial not null primary key,
          created_at                         timestamp not null default now(),
          application_schedule_id 	     integer not null references #{schema_name}.application_schedules,
          affinity_id           	     integer not null references #{schema_name}.affinities,
          unique (application_schedule_id, affinity_id)
      );
      create table #{schema_name}.jobs
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,

          application_id                         integer null references #{schema_name}.applications,
          application_type_id                    integer not null references #{schema_name}.application_types,
          command                                text not null,

          application_run_group_restriction_id   integer not null references #{schema_name}.application_run_group_restrictions,
          application_run_group_name             text null,

          priority                               integer not null default 0,

          started_on_machine_id                  integer null references #{schema_name}.machines,

          failed_to_start                        boolean null,
          started_at                             timestamp null,
          pid                                    integer null,
          finished_at                            timestamp null,
          exit_status                            integer null,
          termination_signal                     integer null,

          request_to_terminate                   boolean not null default false,

          log_level                              text null
      );
      create table #{schema_name}.job_id_created_ats
      (
          id                                 serial not null primary key,
          created_at                         timestamp not null default now(),
          job_id                             integer not null unique,
          job_created_at                     timestamp not null
      );
      create table #{schema_name}.job_affinity_tabs
      (
          id                                 serial not null primary key,
          created_at                         timestamp not null default now(),
          job_id		 	     integer not null references #{schema_name}.jobs,
          affinity_id           	     integer not null references #{schema_name}.affinities,
          unique (job_id, affinity_id)
      );
      create table #{schema_name}.janitorial_assignments
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          type                                   text not null,
          enabled                                boolean not null default true,
          deleted                                boolean not null default false,
          model_name                             text not null,  -- ::Naf::Job
          assignment_order                       integer not null default 0,
          check (deleted = false OR enabled = false)
      );
      insert into #{schema_name}.janitorial_assignments (type, assignment_order, model_name) values
        ('Naf::JanitorialCreateAssignment', 500, '::Naf::Job'),
        ('Naf::JanitorialDropAssignment',   500, '::Naf::Job'),
        ('Naf::JanitorialCreateAssignment', 100, '::Naf::JobIdCreatedAt'),
        ('Naf::JanitorialDropAssignment',   100, '::Naf::JobIdCreatedAt'),
        ('Naf::JanitorialCreateAssignment', 250, '::Naf::JobAffinityTab'),
        ('Naf::JanitorialDropAssignment',   250, '::Naf::JobAffinityTab');

      set search_path = 'public';

    SQL
  end

  def down
    schema_name = Naf::JOB_SYSTEM_SCHEMA_NAME
    execute <<-SQL
      drop table #{schema_name}.janitorial_assignments cascade;
      drop table #{schema_name}.job_affinity_tabs cascade;
      drop table #{schema_name}.job_id_created_ats cascade;
      drop table #{schema_name}.jobs cascade;
      drop table #{schema_name}.affinities cascade;
      drop table #{schema_name}.affinity_classifications cascade;
      drop table #{schema_name}.machines cascade;
      drop table #{schema_name}.machine_affinity_slots cascade;
      drop table #{schema_name}.applications cascade;
      drop table #{schema_name}.application_types cascade;
      drop table #{schema_name}.application_run_group_restrictions cascade;
      drop table #{schema_name}.application_schedules cascade;
      drop table #{schema_name}.application_schedule_affinity_tabs cascade;
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
  end
end
