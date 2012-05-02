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
        ('purpose'), ('identity'), ('application');
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
          available_for_use          boolean not null default true,
          machine_affinity_slot_id   integer not null references naf.machine_affinity_slots,
          thread_pool_size           integer not null default 5,
          is_primary_server          boolean not null default true
      );
      create unique index one_primary_server_udx on naf.machines (is_primary_server) where is_primary_server = true;
    SQL
  end

  def down
  end
end
