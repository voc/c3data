--
-- PostgreSQL database dump
-- pg_dump -W c3data -s > schema.sql
--


--- SETUP


CREATE ROLE graphql WITH PASSWORD 'graphql' LOGIN;
GRANT CONNECT,CREATE,TEMP ON DATABASE c3data TO graphql;
CREATE ROLE viewer NOLOGIN;
GRANT viewer TO graphql;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;



--- TYPES

--
-- Name: event_role; Type: TYPE
--

CREATE TYPE event_role AS ENUM (
    'coordinator',
    'submitter',
    'speaker',
    'moderator',
    'herald',
    'video-camera',
    'video-mixer',
    'video-cutter',
    'video-checker'
);
ALTER TYPE event_role OWNER TO graphql;

--
-- Name: gender; Type: TYPE
--

CREATE TYPE gender AS ENUM (
    'MALE',
    'FEMALE',
    'OTHER'
);
ALTER TYPE gender OWNER TO graphql;

--
-- Name: link; Type: TYPE
--

CREATE TYPE link AS (
    title text,
    url text
);
ALTER TYPE link OWNER TO graphql;



--- TABLES



--
-- Name: conferences; Type: TABLE
--

CREATE TABLE conferences (
    id serial NOT NULL PRIMARY KEY ,
    acronym character varying(255) NOT NULL UNIQUE,
    title character varying(255) NOT NULL,
    timezone character varying(255) DEFAULT 'Berlin'::character varying NOT NULL,
    feedback_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    email character varying(255),
    program_export_base_url character varying(255),
    schedule_version character varying(255),
    schedule_public boolean DEFAULT false NOT NULL,
    color character varying(255),
    default_recording_license character varying(255),
    parent_id integer,
    logo character varying,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    description text,
    url text
);
ALTER TABLE conferences OWNER TO graphql;
GRANT SELECT ON TABLE conferences TO viewer;


CREATE INDEX index_conferences_on_acronym ON conferences USING btree (acronym);
CREATE INDEX index_conferences_on_parent_id ON conferences USING btree (parent_id);


--
-- Name: days; Type: TABLE
--

CREATE TABLE days (
    id bigint NOT NULL PRIMARY KEY ,
    conference_id integer,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    index smallint
);
ALTER TABLE days OWNER TO graphql;
GRANT SELECT ON TABLE days TO viewer;

CREATE INDEX index_days_on_conference ON days USING btree (conference_id);

--
-- Name: events; Type: TABLE
--

CREATE TABLE events (
    guid uuid NOT NULL PRIMARY KEY ,
    conference_id integer NOT NULL,
    title character varying(255) NOT NULL,
    subtitle character varying(255),
    event_type character varying(255) DEFAULT 'talk'::character varying,
    slug character varying(255),
    state character varying(255) DEFAULT 'new'::character varying NOT NULL,
    language character varying(255),
    start_date timestamp with time zone,
    abstract text,
    description text,
    public boolean DEFAULT true,
    logo text,
    track character varying(255),
    room_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    average_rating double precision,
    event_ratings_count integer DEFAULT 0,
    note text,
    do_not_record boolean DEFAULT false,
    recording_license character varying(255),
    tech_rider text,
    links link[],
    attachments link[],
    duration interval,
    local_id integer,
    url text
);
ALTER TABLE events OWNER TO graphql;
GRANT SELECT ON TABLE events TO viewer;

CREATE INDEX index_events_on_conference_id ON events USING btree (conference_id);
CREATE UNIQUE INDEX "index_events_on_local_id-conference_id" ON events USING btree (conference_id, local_id);
CREATE INDEX index_events_on_state ON events USING btree (state);

--
-- Name: people; Type: TABLE
--

CREATE TABLE people (
    guid uuid NOT NULL PRIMARY KEY ,
    first_name character varying(255) DEFAULT ''::character varying,
    last_name character varying(255) DEFAULT ''::character varying,
    public_name character varying(255) NOT NULL,
    email character varying(255),
    email_public boolean DEFAULT true,
    gender character varying(255),
    avatar character varying(255),
    abstract text,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    user_id text,
    note text
);
ALTER TABLE people OWNER TO graphql;
GRANT SELECT ON TABLE people TO viewer;

CREATE INDEX index_people_on_email ON people USING btree (email);
CREATE INDEX index_people_on_user_id ON people USING btree (user_id);



--
-- Name: event_people; Type: TABLE
--

CREATE TABLE event_people (
    id bigint NOT NULL PRIMARY KEY,
    event_id uuid NOT NULL,
    event_role event_role DEFAULT 'speaker'::event_role NOT NULL,
    public_name character varying(255),
    person_guid uuid,
    person_id bigint,
    role_state character varying(255),
    comment character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);
ALTER TABLE event_people OWNER TO graphql;
GRANT SELECT ON TABLE event_people TO viewer;

CREATE INDEX index_event_people_on_event_id ON event_people USING btree (event_id);
CREATE INDEX index_event_people_on_person_id ON event_people USING btree (person_id);


--
-- Name: languages; Type: TABLE
--

CREATE TABLE languages (
    id serial NOT NULL PRIMARY KEY,
    code character varying(255),
    attachable_id integer,
    attachable_type character varying(255),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);
ALTER TABLE languages OWNER TO graphql;
GRANT SELECT ON TABLE languages TO viewer;


CREATE INDEX index_languages_on_attachable_id ON languages USING btree (attachable_id);

--
-- Name: licences; Type: TABLE
--

CREATE TABLE licences (
    id character varying(20) NOT NULL,
    name text,
    url text,
    logo text
);
ALTER TABLE licences OWNER TO graphql;
GRANT SELECT ON TABLE licences TO viewer;

ALTER TABLE ONLY licences
    ADD CONSTRAINT licences_pkey PRIMARY KEY (id);

--
-- Name: rooms; Type: TABLE
--

CREATE TABLE rooms (
    guid uuid DEFAULT uuid_generate_v4()::uuid PRIMARY KEY,
    conference_id integer NOT NULL,
    name character varying(255) NOT NULL,
    size integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    rank integer
);
ALTER TABLE rooms OWNER TO graphql;
GRANT SELECT ON TABLE rooms TO viewer;


CREATE INDEX index_rooms_on_conference_id ON rooms USING btree (conference_id);
CREATE UNIQUE INDEX "index_rooms_on_confernece_id+name" ON rooms USING btree (conference_id, name);
CREATE INDEX index_rooms_on_name ON rooms USING btree (name);


--
-- Name: tags; Type: TABLE
--

CREATE TABLE tags (
    id bigint NOT NULL UNIQUE,
    name character varying(255) PRIMARY KEY,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone NOT NULL,
    color character varying(255) DEFAULT 'fefd7f'::character varying
);
COMMENT ON COLUMN tags.id IS 'Wikidata Q number, or other identifier when there is no item';

ALTER TABLE tags OWNER TO graphql;
GRANT SELECT ON TABLE tags TO viewer;


--  FOREIGN KEY CONSTRAINTS

ALTER TABLE ONLY conferences
    ADD CONSTRAINT conferences_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES conferences(id) ON DELETE CASCADE;

ALTER TABLE ONLY days
    ADD CONSTRAINT days_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES conferences(id) ON DELETE CASCADE;

ALTER TABLE ONLY event_people
    ADD CONSTRAINT event_people_event_id_fkey FOREIGN KEY (event_id) REFERENCES events(guid) ON DELETE CASCADE,
    ADD CONSTRAINT event_people_person_guid_fkey FOREIGN KEY (person_guid) REFERENCES people(guid);

ALTER TABLE ONLY events
    ADD CONSTRAINT events_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES conferences(id) ON DELETE CASCADE,
    ADD CONSTRAINT events_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms(guid) ON DELETE CASCADE;

ALTER TABLE ONLY rooms
    ADD CONSTRAINT rooms_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES conferences(id) ON DELETE CASCADE;


--- FUNCTIONS

--
-- Name: days_date(days); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION days_date(d days) RETURNS date
    LANGUAGE sql STABLE
    AS $$ SELECT d.start_date::date $$;
ALTER FUNCTION days_date(d days) OWNER TO graphql;


--
-- Name: days_events(days); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION days_events(d days) RETURNS events
    LANGUAGE sql STABLE
    AS $$
SELECT e.* 
FROM events e
WHERE d.conference_id = e.conference_id
    AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY e.start_date;
$$;
ALTER FUNCTION days_events(d days) OWNER TO graphql;

--
-- Name: events_day(events); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION events_day(e events) RETURNS days
    LANGUAGE sql STABLE
    AS $$
SELECT d.* 
FROM days d
WHERE d.conference_id = e.conference_id
  AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY d.index DESC
LIMIT 1;
$$;
ALTER FUNCTION events_day(e events) OWNER TO graphql;

--
-- Name: events_day_index(events); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION events_day_index(e events) RETURNS smallint
    LANGUAGE sql STABLE
    AS $$
SELECT d.index AS day 
FROM days d
WHERE d.conference_id = e.conference_id
  AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY day DESC
LIMIT 1;
$$;
ALTER FUNCTION events_day_index(e events) OWNER TO graphql;

--
-- Name: events_duration_time(events); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION events_duration_time(e events) RETURNS text
    LANGUAGE sql STABLE
    AS $$ SELECT to_char(e.duration, 'HH24:MI') $$;
ALTER FUNCTION events_duration_time(e events) OWNER TO graphql;


--
-- Name: events_persons(events, event_role[]); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION events_persons(e events, roles event_role[]) RETURNS SETOF people
    LANGUAGE sql STABLE
    AS $$
    SELECT p.* FROM people p, event_people ep
    WHERE e.guid = ep.event_id AND ep.person_guid = p.guid AND ep.event_role IN( SELECT
      unnest( CASE WHEN roles IS NULL
        THEN ARRAY['speaker', 'moderator']::event_role[]
        ELSE roles
      END
    )::event_role
	)
$$;
ALTER FUNCTION events_persons(e events, roles event_role[]) OWNER TO graphql;

--
-- Name: events_room_name(events); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION events_room_name(e events) RETURNS text
    LANGUAGE sql STABLE
    AS $$
SELECT r.name 
FROM rooms r
WHERE r.conference_id = e.conference_id
  AND r.guid = e.room_id
$$;
ALTER FUNCTION events_room_name(e events) OWNER TO graphql;

--
-- Name: events_start_time(events); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION events_start_time(e events) RETURNS text
    LANGUAGE sql STABLE
    AS $$ SELECT to_char(e.start_date, 'HH24:MI') $$;
ALTER FUNCTION events_start_time(e events) OWNER TO graphql;



--- TRIGGER


--
-- Name: before_change(); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION before_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF TG_OP <> 'DELETE' THEN
            NEW.updated_at = now();
            RETURN NEW;
        END IF;
        RETURN OLD;
      END;
    $$;
ALTER FUNCTION before_change() OWNER TO graphql;



--
-- Name: send_change_event(); Type: FUNCTION
--

CREATE OR REPLACE FUNCTION send_change_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    notification json;
  BEGIN
    notification := json_build_object(
      'table', TG_TABLE_NAME,
      'action', TG_OP,
      'old', CASE WHEN TG_OP <> 'INSERT' THEN row_to_json(OLD) END,
      'new', CASE WHEN TG_OP <> 'DELETE' THEN row_to_json(NEW) END
    );
    PERFORM pg_notify('change', notification::text);
    RETURN NULL;
  END;
$$;
ALTER FUNCTION send_change_event() OWNER TO graphql;


CREATE TRIGGER conference_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON conferences FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER conference_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON conferences FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER event_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON events FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER event_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON events FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER person_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON people FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER person_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON people FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER room_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON rooms FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER room_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON rooms FOR EACH ROW EXECUTE PROCEDURE send_change_event();





--
-- PostgreSQL database dump complete
--




--
-- Name: postgraphile_watch
-- @see https://github.com/graphile/postgraphile/blob/886f8752f03d3fa05bdbdd97eeabb153a4d0343e/resources/watch-fixtures.sql

-- Adds the functionality for PostGraphile to watch the database for schema
-- changes. This script is idempotent, you can run it as many times as you
-- would like.

-- Drop the `postgraphile_watch` schema and all of its dependant objects
-- including the event trigger function and the event trigger itself. We will
-- recreate those objects in this script.
drop schema if exists postgraphile_watch cascade;

-- Create a schema for the PostGraphile watch functionality. This schema will
-- hold things like trigger functions that are used to implement schema
-- watching.
create schema postgraphile_watch;

create function postgraphile_watch.notify_watchers_ddl() returns event_trigger as $$
begin
  perform pg_notify(
    'postgraphile_watch',
    json_build_object(
      'type',
      'ddl',
      'payload',
      (select json_agg(json_build_object('schema', schema_name, 'command', command_tag)) from pg_event_trigger_ddl_commands() as x)
    )::text
  );
end;
$$ language plpgsql;

create function postgraphile_watch.notify_watchers_drop() returns event_trigger as $$
begin
  perform pg_notify(
    'postgraphile_watch',
    json_build_object(
      'type',
      'drop',
      'payload',
      (select json_agg(distinct x.schema_name) from pg_event_trigger_dropped_objects() as x)
    )::text
  );
end;
$$ language plpgsql;

-- Create an event trigger which will listen for the completion of all DDL
-- events and report that they happened to PostGraphile. Events are selected by
-- whether or not they modify the static definition of `pg_catalog` that
-- `introspection-query.sql` queries.
create event trigger postgraphile_watch_ddl
  on ddl_command_end
  when tag in (
    -- Ref: https://www.postgresql.org/docs/10/static/event-trigger-matrix.html
    'ALTER AGGREGATE',
    'ALTER DOMAIN',
    'ALTER EXTENSION',
    'ALTER FOREIGN TABLE',
    'ALTER FUNCTION',
    'ALTER POLICY',
    'ALTER SCHEMA',
    'ALTER TABLE',
    'ALTER TYPE',
    'ALTER VIEW',
    'COMMENT',
    'CREATE AGGREGATE',
    'CREATE DOMAIN',
    'CREATE EXTENSION',
    'CREATE FOREIGN TABLE',
    'CREATE OR REPLACE FUNCTION ',
    'CREATE INDEX',
    'CREATE POLICY',
    'CREATE RULE',
    'CREATE SCHEMA',
    'CREATE TABLE',
    'CREATE TABLE AS',
    'CREATE VIEW',
    'DROP AGGREGATE',
    'DROP DOMAIN',
    'DROP EXTENSION',
    'DROP FOREIGN TABLE',
    'DROP FUNCTION',
    'DROP INDEX',
    'DROP OWNED',
    'DROP POLICY',
    'DROP RULE',
    'DROP SCHEMA',
    'DROP TABLE',
    'DROP TYPE',
    'DROP VIEW',
    'GRANT',
    'REVOKE',
    'SELECT INTO'
  )
  execute procedure postgraphile_watch.notify_watchers_ddl();

-- Create an event trigger which will listen for drop events because on drops
-- the DDL method seems to get nothing returned from
-- pg_event_trigger_ddl_commands()
create event trigger postgraphile_watch_drop
  on sql_drop
  execute procedure postgraphile_watch.notify_watchers_drop();

