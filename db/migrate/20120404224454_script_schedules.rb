class ScriptSchedules < ActiveRecord::Migration
  def up
    # affinities
    #  names: normal, canary, perennial
    #  location: ip address
    #  application/release on machine: application-release-number
    sql <<-SQL
      create schema naf;
      create table naf.affinity_classifications
      (
          id                             serial not null primary key,
          created_at                     timestamp not null default now(),
          updated_at                     timestamp,
          affinity_classification_name   text not null unique
      );
      insert into naf.affinity_classifications (affinity_classification_name) values
        ('purpose'), ('location'), ('application');
      create table naf.affinities
      (
          id                            serial not null primary key,
          created_at                    timestamp not null default now(),
          updated_at                    timestamp,
          selectable                    boolean not null default true,
          affinity_classification_id    integer not null references naf.affinity_classifications,
          affinity_name                 text not null,
          unique (affinity_classification_id, affinity_name)
      );
      insert into naf.affinities (affinity_classification_id, affinity_name) values
         ((select id from naf.affinity_classifications where affinity_classification_name = 'purpose'), 'normal'),
         ((select id from naf.affinity_classifications where affinity_classification_name = 'purpose'), 'canary'),
         ((select id from naf.affinity_classifications where affinity_classification_name = 'purpose'), 'perennial');
      create table naf.machine_affinity_slots
      (
          id                               serial not null primary key,
          created_at                       timestamp not null default now(),
          updated_at                       timestamp,
          selectable                       boolean not null default true,
          machine_affinity_slot_name       text not null unique
      );
      create table naf.machine_affinity_slot_pieces
      (
          id                                        serial not null primary key,
          created_at                                timestamp not null default now(),
          machine_affinity_slot_id	            integer not null references naf.machine_affinity_slots,
          affinity_id                        	    integer not null references naf.affinities,
          required                                  boolean not null default false,
          unique (machine_affinity_slot_id, affinity_id)
      );
      create table naf.application_affinity_tabs
      (
          id                               serial not null primary key,
          created_at                       timestamp not null default now(),
          updated_at                       timestamp,
          selectable                       boolean not null default true,
          application_affinity_tab_name    text not null unique
      );
      create table naf.application_affinity_tab_pieces
      (
          id                                 serial not null primary key,
          created_at                         timestamp not null default now(),
          application_affinity_tab_id        integer not null references naf.application_affinity_tabs,
          affinity_id           	     integer not null references naf.affinities,
          unique (application_affinity_tab_id, affinity_id)
      );
      create table naf.machines
      (
          id                         serial not null primary key,
          created_at                 timestamp not null default now(),
          updated_at                 timestamp,
          server_address             inet not null unique,
          server_name                text,
          server_note                text,
          enabled                    boolean not null default true,
          machine_affinity_slot_id   integer not null references naf.machine_affinity_slots,
          thread_pool_size           integer not null default 5,
          last_checked_schedules_at  timestamp null
      );
      create table naf.application_types
      (
          id                  serial not null primary key,
          created_at          timestamp not null default now(),
          updated_at          timestamp,
          enabled             boolean not null default true,
          script_type_name    text unique not null,
          description         text,
          invocation_class    text not null
      );
      insert into naf.application_types (script_type_name, description, invocation_class) values
        ('rails', 'ruby on rails NAF application', '::Naf::ApplicationType.rails_invocator'),
        ('bash command', 'bash command', '::Naf::ApplicationType.bash_command_invocator'),
        ('bash script', 'bash script', '::Naf::ApplicationType.bash_script_invocator'),
        ('ruby', 'ruby script', '::Naf::ApplicationType.ruby_script_invocator');
      create table naf.applications
      (
          id                              serial not null primary key,
          created_at                      timestamp not null default now(),
          updated_at                      timestamp,
          deleted                         boolean not null default false,
          application_type_id	          integer not null references naf.application_types,
          command                         text not null,
          title                           text not null
      );
      create table naf.application_run_groups
      (
          id                              serial not null primary key,
          created_at                      timestamp not null default now(),
          application_run_group_name      text unique not null
      );
      create table naf.application_run_group_restrictions
      (
          id                                        serial not null primary key,
          created_at                                timestamp not null default now(),
          application_run_group_restriction_name    text unique not null
      );
      insert into naf.application_run_group_restrictions (application_run_group_restriction_name) values
         ('no restrictions', 'one at a time', 'one per machine');
      create table naf.application_schedules
      (
          id                                     serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          enabled                                boolean not null default true,
          visible                                boolean not null default true,
          application_id                         integer not null references naf.applications,
          application_affinity_tab_id            integer not null references naf.application_affinity_tabs,
          application_run_group_id               integer not null references naf.application_run_groups,
          application_run_group_restriction_id   integer not null references naf.application_run_group_restrictions,
          run_interval                           integer not null,
          priority                               integer not null default 0,
          check (visible = true or enabled = false)
      );
      create unique index applications_have_one_schedule_udx on naf.application_schedules (application_id) where enabled = true;
    SQL
  end

  def down
    sql <<-SQL
      drop table naf.application_schedules;
      drop table naf.application_run_group_restrictions;
      drop table naf.application_run_groups;
      drop table naf.applications;
      drop table naf.application_types;
      drop table naf.machines;
      drop table naf.application_affinity_tab_pieces;
      drop table naf.application_affinity_tabs;
      drop table naf.machine_affinity_slot_pieces;
      drop table naf.machine_affinity_slots;
      drop table naf.affinities;
      drop table naf.affinity_classifications;
      drop schema naf;
    SQL
  end
end
