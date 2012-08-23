--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: naf; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA naf;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = naf, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: affinities; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE affinities (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    selectable boolean DEFAULT true NOT NULL,
    affinity_classification_id integer NOT NULL,
    affinity_name text NOT NULL
);


--
-- Name: affinities_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE affinities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: affinities_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE affinities_id_seq OWNED BY affinities.id;


--
-- Name: affinity_classifications; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE affinity_classifications (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    affinity_classification_name text NOT NULL
);


--
-- Name: affinity_classifications_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE affinity_classifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: affinity_classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE affinity_classifications_id_seq OWNED BY affinity_classifications.id;


--
-- Name: application_run_group_restrictions; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE application_run_group_restrictions (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    application_run_group_restriction_name text NOT NULL
);


--
-- Name: application_run_group_restrictions_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE application_run_group_restrictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: application_run_group_restrictions_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE application_run_group_restrictions_id_seq OWNED BY application_run_group_restrictions.id;


--
-- Name: application_schedule_affinity_tabs; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE application_schedule_affinity_tabs (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    application_schedule_id integer NOT NULL,
    affinity_id integer NOT NULL
);


--
-- Name: application_schedule_affinity_tabs_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE application_schedule_affinity_tabs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: application_schedule_affinity_tabs_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE application_schedule_affinity_tabs_id_seq OWNED BY application_schedule_affinity_tabs.id;


--
-- Name: application_schedules; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE application_schedules (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    enabled boolean DEFAULT true NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    application_id integer NOT NULL,
    application_run_group_restriction_id integer NOT NULL,
    application_run_group_name text,
    run_interval integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    CONSTRAINT application_schedules_check CHECK (((visible = true) OR (enabled = false)))
);


--
-- Name: application_schedules_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE application_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: application_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE application_schedules_id_seq OWNED BY application_schedules.id;


--
-- Name: application_types; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE application_types (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    enabled boolean DEFAULT true NOT NULL,
    script_type_name text NOT NULL,
    description text,
    invocation_method text NOT NULL
);


--
-- Name: application_types_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE application_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: application_types_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE application_types_id_seq OWNED BY application_types.id;


--
-- Name: applications; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE applications (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    deleted boolean DEFAULT false NOT NULL,
    application_type_id integer NOT NULL,
    command text NOT NULL,
    title text NOT NULL,
    log_level text
);


--
-- Name: applications_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applications_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE applications_id_seq OWNED BY applications.id;


--
-- Name: job_affinity_tabs; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE job_affinity_tabs (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    job_id integer NOT NULL,
    affinity_id integer NOT NULL
);


--
-- Name: job_affinity_tabs_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE job_affinity_tabs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_affinity_tabs_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE job_affinity_tabs_id_seq OWNED BY job_affinity_tabs.id;


--
-- Name: jobs; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE jobs (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    application_id integer,
    application_type_id integer NOT NULL,
    command text NOT NULL,
    application_run_group_restriction_id integer NOT NULL,
    application_run_group_name text,
    priority integer DEFAULT 0 NOT NULL,
    started_on_machine_id integer,
    failed_to_start boolean,
    started_at timestamp without time zone,
    pid integer,
    finished_at timestamp without time zone,
    exit_status integer,
    termination_signal integer,
    request_to_terminate boolean DEFAULT false NOT NULL,
    log_level text
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- Name: machine_affinity_slots; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE machine_affinity_slots (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    machine_id integer NOT NULL,
    affinity_id integer NOT NULL,
    required boolean DEFAULT false NOT NULL
);


--
-- Name: machine_affinity_slots_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE machine_affinity_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machine_affinity_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE machine_affinity_slots_id_seq OWNED BY machine_affinity_slots.id;


--
-- Name: machines; Type: TABLE; Schema: naf; Owner: -; Tablespace: 
--

CREATE TABLE machines (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    server_address inet NOT NULL,
    server_name text,
    server_note text,
    enabled boolean DEFAULT true NOT NULL,
    thread_pool_size integer DEFAULT 5 NOT NULL,
    last_checked_schedules_at timestamp without time zone,
    last_seen_alive_at timestamp without time zone,
    log_level text
);


--
-- Name: machines_id_seq; Type: SEQUENCE; Schema: naf; Owner: -
--

CREATE SEQUENCE machines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machines_id_seq; Type: SEQUENCE OWNED BY; Schema: naf; Owner: -
--

ALTER SEQUENCE machines_id_seq OWNED BY machines.id;


SET search_path = public, pg_catalog;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


SET search_path = naf, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY affinities ALTER COLUMN id SET DEFAULT nextval('affinities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY affinity_classifications ALTER COLUMN id SET DEFAULT nextval('affinity_classifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_run_group_restrictions ALTER COLUMN id SET DEFAULT nextval('application_run_group_restrictions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_schedule_affinity_tabs ALTER COLUMN id SET DEFAULT nextval('application_schedule_affinity_tabs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_schedules ALTER COLUMN id SET DEFAULT nextval('application_schedules_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_types ALTER COLUMN id SET DEFAULT nextval('application_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY applications ALTER COLUMN id SET DEFAULT nextval('applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY job_affinity_tabs ALTER COLUMN id SET DEFAULT nextval('job_affinity_tabs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY jobs ALTER COLUMN id SET DEFAULT nextval('jobs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY machine_affinity_slots ALTER COLUMN id SET DEFAULT nextval('machine_affinity_slots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: naf; Owner: -
--

ALTER TABLE ONLY machines ALTER COLUMN id SET DEFAULT nextval('machines_id_seq'::regclass);


--
-- Name: affinities_affinity_classification_id_affinity_name_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY affinities
    ADD CONSTRAINT affinities_affinity_classification_id_affinity_name_key UNIQUE (affinity_classification_id, affinity_name);


--
-- Name: affinities_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY affinities
    ADD CONSTRAINT affinities_pkey PRIMARY KEY (id);


--
-- Name: affinity_classifications_affinity_classification_name_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY affinity_classifications
    ADD CONSTRAINT affinity_classifications_affinity_classification_name_key UNIQUE (affinity_classification_name);


--
-- Name: affinity_classifications_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY affinity_classifications
    ADD CONSTRAINT affinity_classifications_pkey PRIMARY KEY (id);


--
-- Name: application_run_group_restric_application_run_group_restric_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_run_group_restrictions
    ADD CONSTRAINT application_run_group_restric_application_run_group_restric_key UNIQUE (application_run_group_restriction_name);


--
-- Name: application_run_group_restrictions_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_run_group_restrictions
    ADD CONSTRAINT application_run_group_restrictions_pkey PRIMARY KEY (id);


--
-- Name: application_schedule_affinity_application_schedule_id_affin_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_schedule_affinity_tabs
    ADD CONSTRAINT application_schedule_affinity_application_schedule_id_affin_key UNIQUE (application_schedule_id, affinity_id);


--
-- Name: application_schedule_affinity_tabs_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_schedule_affinity_tabs
    ADD CONSTRAINT application_schedule_affinity_tabs_pkey PRIMARY KEY (id);


--
-- Name: application_schedules_application_id_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_schedules
    ADD CONSTRAINT application_schedules_application_id_key UNIQUE (application_id);


--
-- Name: application_schedules_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_schedules
    ADD CONSTRAINT application_schedules_pkey PRIMARY KEY (id);


--
-- Name: application_types_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_types
    ADD CONSTRAINT application_types_pkey PRIMARY KEY (id);


--
-- Name: application_types_script_type_name_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY application_types
    ADD CONSTRAINT application_types_script_type_name_key UNIQUE (script_type_name);


--
-- Name: applications_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: job_affinity_tabs_job_id_affinity_id_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job_affinity_tabs
    ADD CONSTRAINT job_affinity_tabs_job_id_affinity_id_key UNIQUE (job_id, affinity_id);


--
-- Name: job_affinity_tabs_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job_affinity_tabs
    ADD CONSTRAINT job_affinity_tabs_pkey PRIMARY KEY (id);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: machine_affinity_slots_machine_id_affinity_id_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machine_affinity_slots
    ADD CONSTRAINT machine_affinity_slots_machine_id_affinity_id_key UNIQUE (machine_id, affinity_id);


--
-- Name: machine_affinity_slots_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machine_affinity_slots
    ADD CONSTRAINT machine_affinity_slots_pkey PRIMARY KEY (id);


--
-- Name: machines_pkey; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);


--
-- Name: machines_server_address_key; Type: CONSTRAINT; Schema: naf; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT machines_server_address_key UNIQUE (server_address);


--
-- Name: applications_have_one_schedule_udx; Type: INDEX; Schema: naf; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX applications_have_one_schedule_udx ON application_schedules USING btree (application_id) WHERE (enabled = true);


SET search_path = public, pg_catalog;

--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


SET search_path = naf, pg_catalog;

--
-- Name: affinities_affinity_classification_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY affinities
    ADD CONSTRAINT affinities_affinity_classification_id_fkey FOREIGN KEY (affinity_classification_id) REFERENCES affinity_classifications(id);


--
-- Name: application_schedule_affinity_tabs_affinity_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_schedule_affinity_tabs
    ADD CONSTRAINT application_schedule_affinity_tabs_affinity_id_fkey FOREIGN KEY (affinity_id) REFERENCES affinities(id);


--
-- Name: application_schedule_affinity_tabs_application_schedule_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_schedule_affinity_tabs
    ADD CONSTRAINT application_schedule_affinity_tabs_application_schedule_id_fkey FOREIGN KEY (application_schedule_id) REFERENCES application_schedules(id);


--
-- Name: application_schedules_application_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_schedules
    ADD CONSTRAINT application_schedules_application_id_fkey FOREIGN KEY (application_id) REFERENCES applications(id);


--
-- Name: application_schedules_application_run_group_restriction_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY application_schedules
    ADD CONSTRAINT application_schedules_application_run_group_restriction_id_fkey FOREIGN KEY (application_run_group_restriction_id) REFERENCES application_run_group_restrictions(id);


--
-- Name: applications_application_type_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_application_type_id_fkey FOREIGN KEY (application_type_id) REFERENCES application_types(id);


--
-- Name: job_affinity_tabs_affinity_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY job_affinity_tabs
    ADD CONSTRAINT job_affinity_tabs_affinity_id_fkey FOREIGN KEY (affinity_id) REFERENCES affinities(id);


--
-- Name: job_affinity_tabs_job_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY job_affinity_tabs
    ADD CONSTRAINT job_affinity_tabs_job_id_fkey FOREIGN KEY (job_id) REFERENCES jobs(id);


--
-- Name: jobs_application_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_application_id_fkey FOREIGN KEY (application_id) REFERENCES applications(id);


--
-- Name: jobs_application_run_group_restriction_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_application_run_group_restriction_id_fkey FOREIGN KEY (application_run_group_restriction_id) REFERENCES application_run_group_restrictions(id);


--
-- Name: jobs_application_type_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_application_type_id_fkey FOREIGN KEY (application_type_id) REFERENCES application_types(id);


--
-- Name: jobs_started_on_machine_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_started_on_machine_id_fkey FOREIGN KEY (started_on_machine_id) REFERENCES machines(id);


--
-- Name: machine_affinity_slots_affinity_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY machine_affinity_slots
    ADD CONSTRAINT machine_affinity_slots_affinity_id_fkey FOREIGN KEY (affinity_id) REFERENCES affinities(id);


--
-- Name: machine_affinity_slots_machine_id_fkey; Type: FK CONSTRAINT; Schema: naf; Owner: -
--

ALTER TABLE ONLY machine_affinity_slots
    ADD CONSTRAINT machine_affinity_slots_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES machines(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20120823203410');