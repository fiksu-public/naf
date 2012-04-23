class ScriptSchedules < ActiveRecord::Migration
  def up
    sql <<-SQL
      create schema script_scheduler;
      create table script_scheduler.affinities
      (
          id                   serial not null primary key,
          created_at           timestamp not null default now(),
          updated_at           timestamp,
          selectable           boolean not null default true,
          affinity_name        text not null unique
      );
      insert into script_scheduler.affinities (affinity_name) values ('normal'), ('canary'), ('perenial');
      create table script_scheduler.affinity_slots
      (
          id                               serial not null primary key,
          created_at                       timestamp not null default now(),
          updated_at                       timestamp,
          selectable                       boolean not null default true,
          affinity_slot_name               text not null unique
      );
      create table script_scheduler.affinity_slot_pieces
      (
          id                                        serial not null primary key,
          created_at                                timestamp not null default now(),
          affinity_slot_id    		            integer not null references script_scheduler.affinity_slots,
          affinity_id                        	    integer not null references script_scheduler.affinities,
          required                                  boolean not null default false,
          unique (script_scheduler.affinity_slot_id, script_scheduler.affinity_id)
      );
      create table script_scheduler.affinity_tabs
      (
          id                               serial not null primary key,
          created_at                       timestamp not null default now(),
          updated_at                       timestamp,
          selectable                       boolean not null default true,
          affinity_tab_name                text not null unique
      );
      create table script_scheduler.affinity_tab_pieces
      (
          id                                 serial not null primary key,
          created_at                         timestamp not null default now(),
          affinity_tab_id	             integer not null references script_scheduler.affinity_tabs,
          affinity_id           	     integer not null references script_scheduler.affinities,
          unique (affinity_tab_id, affinity_id)
      );
      create table script_scheduler.machines
      (
          id                         serial not null primary key,
          created_at                 timestamp not null default now(),
          updated_at                 timestamp,
          server_address             inet not null unique,
          server_name                text,
          server_note                text,
          available_for_use          boolean not null default true
      );
      create table script_scheduler.runner_machine_configurations
      (
          id                         serial not null primary key,
          created_at                 timestamp not null default now(),
          updated_at                 timestamp,
          machine_id 		     integer not null references script_scheduler.machines,
          affinity_slot_id    	     integer not null references script_scheduler.affinity_slots,
          enabled                    boolean not null default true,
          thread_pool_size           integer not null default 5,
          extra_arguments            text
      );
      create table script_scheduler.scheduler_machine_configurations
      (
          id                         serial not null primary key,
          created_at                 timestamp not null default now(),
          updated_at                 timestamp,
          machine_id	             integer not null references script_scheduler.machines,
          enabled                    boolean not null default false,
          extra_arguments            text
      );
      create table script_scheduler.application_tags
      (
          id                   serial not null primary key,
          created_at           timestamp not null default now(),
          updated_at           timestamp,
          selectable           boolean not null default true,
          application_tag_name text not null unique
      );
      create table script_scheduler.application_types
      (
          id                  serial not null primary key,
          created_at          timestamp not null default now(),
          updated_at          timestamp,
          enabled             boolean not null default true,
          script_type_name    text unique not null,
          description         text,
          invocation_class    text not null
      );
      create table script_scheduler.applications
      (
          id                              serial not null primary key,
          created_at                      timestamp not null default now(),
          updated_at                      timestamp,
          deleted                         boolean not null default false,
          application_type_id	          integer not null references script_scheduler.application_types,
          command                         text not null,
          title                           text not null
      );
      create table script_scheduler.application_run_groups
      (
          id                              serial not null primary key,
          created_at                      timestamp not null default now(),
          application_run_group_name      text unique not null
      );
      create table script_scheduler.application_run_group_restrictions
      (
          id                  serial not null primary key,
          created_at          timestamp not null default now(),
          restriction_name    text unique not null
      );
      create table script_scheduler.application_schedules
      (
          id                                    serial not null primary key,
          created_at                             timestamp not null default now(),
          updated_at                             timestamp,
          enabled                                boolean not null default true,
          visible                                boolean not null default true,
          application_id                         integer not null references scheduler_scheduler.scripts,
          affinity_tab_id                        integer not null references scheduler_scheduler.affinity_tabs,
          application_run_group_id               integer not null references scheduler_scheduler.application_run_groups,
          application_run_group_restriction_id   integer not null references scheduler_scheduler.application_run_group_restrictions,
          run_interval                           integer not null,
          priority                               integer,
          check (visible = true or enabled = false)
      );
      create table script_scheduler.application_run_history
      (
          id                  serial not null primary key,
          created_at          timestamp not null default now(),
          updated_at          timestamp,
          script_schedule_id  integer references script_schedules,
          script_id           integer references scripts,
          affinity            text not null,
          run_group_name      text not null,
          script_type_name    text not null,
          command             text not null,
          title               text not null,
          priority            integer not null,
          run_requested_by    text not null,
          run_requested_from  inet not null,
          started_at          timestamp not null default now(),
          started_on_server   integer not null references script_scheduler.runner_machine_configurations,
          thread_number       integer not null,
          pid                 integer not null,
          finished_at         timestamp null,
          exit_status         integer not null,
          signaled_to_exit    boolean null,
          termination_signal  integer null,
          finished            boolean not null default false,
          failed_to_start     boolean not null default false,
          killed              boolean no tnull default false
      );
    SQL
  end

  def down
  end
end
