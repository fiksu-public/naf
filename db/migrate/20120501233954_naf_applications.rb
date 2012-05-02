class NafApplications < ActiveRecord::Migration
  def up
    <<-SQL
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
          priority                               integer,
          check (visible = true or enabled = false)
      );
      create table naf.application_run_history
      (
          id                         serial not null primary key,
          created_at                 timestamp not null default now(),
          updated_at                 timestamp,
          application_schedule_id    integer references naf.application_schedules,
          affinity            text not null,
          run_group_name      text not null,
          script_type_name    text not null,
          command             text not null,
          title               text not null,
          priority            integer not null,
          run_requested_by    text not null,
          run_requested_from  inet not null,
          started_at          timestamp not null default now(),
          started_on_server   integer not null references naf.runner_machine_configurations,
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
