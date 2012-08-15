class CreateJobSystem < ActiveRecord::Migration
  SCHEMA_NAME = '<%= schema_name %>'

  def up
    # Define a schema_name, the scheduling tables fall under:
    schema_name = SCHEMA_NAME

    # affinities
    #  names: normal, canary, perennial
    #  location: ip address
    #  application/release on machine: application-release-number
    sql <<-SQL
      create schema #{schema_name};
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
          last_seen_alive_at         timestamp null
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
          invocation_class    text not null
      );
      insert into #{schema_name}.application_types (script_type_name, description, invocation_class) values
        ('rails', 'ruby on rails NAF application', '::Naf::ApplicationType.rails_invocator'),
        ('bash command', 'bash command', '::Naf::ApplicationType.bash_command_invocator'),
        ('bash script', 'bash script', '::Naf::ApplicationType.bash_script_invocator'),
        ('ruby', 'ruby script', '::Naf::ApplicationType.ruby_script_invocator');
      create table #{schema_name}.applications
      (
          id                              serial not null primary key,
          created_at                      timestamp not null default now(),
          updated_at                      timestamp,
          deleted                         boolean not null default false,
          application_type_id	          integer not null references #{schema_name}.application_types,
          command                         text not null,
          title                           text not null
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
          application_id                         integer not null references #{schema_name}.applications,
          application_run_group_restriction_id   integer not null references #{schema_name}.application_run_group_restrictions,
          application_run_group_name             text null,
          run_interval                           integer not null,
          priority                               integer not null default 0,
          check (visible = true or enabled = false)
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

          application_id                         integer not null references #{schema_name}.applications,

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

          request_to_terminate                   boolean not null default false
      );
      create table #{schema_name}.job_affinity_tabs
      (
          id                                 serial not null primary key,
          created_at                         timestamp not null default now(),
          job_id		 	     integer not null references #{schema_name}.jobs,
          affinity_id           	     integer not null references #{schema_name}.affinities,
          unique (job_id, affinity_id)
      );
    SQL
  end

  def down
    schema_name = SCHEMA_NAME
    sql <<-SQL
      drop schema #{schema_name} cascade;
    SQL
  end
end
