--
-- PostgreSQL database dump
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
SET client_min_messages = warning;
SET row_security = off;


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
    'CREATE FUNCTION',
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




--- SCHEMA


--
-- Name: event_role; Type: TYPE; Schema: public; Owner: graphql
--

CREATE TYPE public.event_role AS ENUM (
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


ALTER TYPE public.event_role OWNER TO graphql;

--
-- Name: gender; Type: TYPE; Schema: public; Owner: graphql
--

CREATE TYPE public.gender AS ENUM (
    'MALE',
    'FEMALE',
    'OTHER'
);


ALTER TYPE public.gender OWNER TO graphql;

--
-- Name: link; Type: TYPE; Schema: public; Owner: graphql
--

CREATE TYPE public.link AS (
    title text,
    url text
);


ALTER TYPE public.link OWNER TO graphql;

--
-- Name: before_change(); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION before_change() RETURNS TRIGGER  LANGUAGE plpgsql AS $$
  BEGIN
    IF TG_OP <> 'DELETE' THEN
      NEW.updated_at = now();
      RETURN NEW;
    END IF;
    RETURN OLD;
  END;
$$;

ALTER FUNCTION public.before_change() OWNER TO graphql;

--
-- Name: days; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.days (
    id bigserial NOT NULL,
    conference_id bigint,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    index smallint
);


ALTER TABLE public.days OWNER TO graphql;


--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id bigserial NOT NULL,
    conference_id bigint NOT NULL,
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
    track_id integer,
    room_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    average_rating double precision,
    event_ratings_count integer DEFAULT 0,
    note text,
    guid character varying(255) NOT NULL,
    do_not_record boolean DEFAULT false,
    recording_license character varying(255),
    tech_rider text,
    links public.link[],
    attachments public.link[],
    duration interval,
    local_id integer
);


ALTER TABLE public.events OWNER TO graphql;

--
-- Name: people; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.people (
    id bigserial NOT NULL,
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
    user_id integer,
    note text,
    include_in_mailings boolean DEFAULT false NOT NULL,
    use_gravatar boolean DEFAULT false NOT NULL
);


ALTER TABLE public.people OWNER TO graphql;

--
-- Name: conferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conferences (
    id bigserial NOT NULL,
    acronym character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    timezone character varying(255) DEFAULT 'Berlin'::character varying NOT NULL,
    feedback_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    email character varying(255),
    program_export_base_url character varying(255),
    schedule_version character varying(255),
    schedule_public boolean DEFAULT false NOT NULL,
    color character varying(255),
    default_recording_license character varying(255),
    parent_id integer,
    logo character varying,
    start_date timestamp with time zone,
    end_date timestamp with time zone
);


ALTER TABLE public.conferences OWNER TO graphql;


--
-- Name: event_people; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_people (
    id bigserial NOT NULL,
    event_id integer NOT NULL,
    person_id integer NOT NULL,
    event_role public.event_role DEFAULT 'speaker'::public.event_role NOT NULL,
    role_state character varying(255),
    comment character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    confirmation_token character varying(255),
    notification_subject character varying(255),
    notification_body text
);


ALTER TABLE public.event_people OWNER TO graphql;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.languages (
    id bigserial NOT NULL,
    code character varying(255),
    attachable_id integer,
    attachable_type character varying(255),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone
);


ALTER TABLE public.languages OWNER TO graphql;

--
-- Name: rooms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rooms (
    id bigserial NOT NULL,
    conference_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    size integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    rank integer
);


ALTER TABLE public.rooms OWNER TO graphql;

--
-- Name: tracks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tracks (
    id bigserial NOT NULL,
    conference_id bigint,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '2018-10-07 14:06:49.211567'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    color character varying(255) DEFAULT 'fefd7f'::character varying
);


ALTER TABLE public.tracks OWNER TO graphql;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigserial NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    remember_created_at timestamp without time zone,
    remember_token character varying(255),
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone,
    role character varying(255) DEFAULT 'submitter'::character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO graphql;

--
-- Name: versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versions (
    id bigserial NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id integer NOT NULL,
    event character varying(255) NOT NULL,
    whodunnit character varying(255),
    object text,
    created_at timestamp with time zone,
    conference_id bigint,
    associated_id integer,
    associated_type character varying(255),
    object_changes text
);


ALTER TABLE public.versions OWNER TO graphql;



CREATE TABLE tags (
    id bigserial NOT NULL,
    name character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    color character varying(255) DEFAULT 'fefd7f'::character varying
);
COMMENT ON COLUMN tags.id IS 'Wikidata Q number, or other identifier when there is no item';

ALTER TABLE tags OWNER TO graphql;
GRANT SELECT ON TABLE tags TO viewer;

--
-- Name: conferences conferences_acronym_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conferences
    ADD CONSTRAINT conferences_acronym_key UNIQUE (acronym);


--
-- Name: conferences conferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conferences
    ADD CONSTRAINT conferences_pkey PRIMARY KEY (id);


--
-- Name: days days_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days
    ADD CONSTRAINT days_pkey PRIMARY KEY (id);


--
-- Name: event_people event_people_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_people
    ADD CONSTRAINT event_people_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: tracks tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: index_conferences_on_acronym; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_conferences_on_acronym ON public.conferences USING btree (acronym);


--
-- Name: index_conferences_on_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_conferences_on_parent_id ON public.conferences USING btree (parent_id);


--
-- Name: index_days_on_conference; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_days_on_conference ON public.days USING btree (conference_id);


--
-- Name: index_event_people_on_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_event_people_on_event_id ON public.event_people USING btree (event_id);


--
-- Name: index_event_people_on_person_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_event_people_on_person_id ON public.event_people USING btree (person_id);


--
-- Name: index_events_on_conference_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_events_on_conference_id ON public.events USING btree (conference_id);


--
-- Name: index_events_on_guid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_events_on_guid ON public.events USING btree (guid);


--
-- Name: index_events_on_local_id-conference_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "index_events_on_local_id-conference_id" ON public.events USING btree (conference_id, local_id);


--
-- Name: index_events_on_state; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_events_on_state ON public.events USING btree (state);


--
-- Name: index_events_on_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_events_on_type ON public.events USING btree (event_type);


--
-- Name: index_languages_on_attachable_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_languages_on_attachable_id ON public.languages USING btree (attachable_id);


--
-- Name: index_people_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_people_on_email ON public.people USING btree (email);


--
-- Name: index_people_on_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_people_on_user_id ON public.people USING btree (user_id);


--
-- Name: index_rooms_on_conference_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_rooms_on_conference_id ON public.rooms USING btree (conference_id);


--
-- Name: index_tracks_on_conference_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_tracks_on_conference_id ON public.tracks USING btree (conference_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);



--
-- Name: days_date(public.days); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.days_date(d public.days) RETURNS date
    LANGUAGE sql STABLE
    AS $$ SELECT d.start_date::date $$;


ALTER FUNCTION public.days_date(d public.days) OWNER TO graphql;


--
-- Name: days_events(public.days); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.days_events(d public.days) RETURNS public.events
    LANGUAGE sql STABLE
    AS $$
SELECT e.*
FROM events e
WHERE d.conference_id = e.conference_id
    AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY e.start_date;
$$;


ALTER FUNCTION public.days_events(d public.days) OWNER TO graphql;

--
-- Name: events_day(public.events); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.events_day(e public.events) RETURNS public.days
    LANGUAGE sql STABLE
    AS $$
SELECT d.*
FROM days d
WHERE d.conference_id = e.conference_id
  AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY d.index DESC
LIMIT 1;
$$;


ALTER FUNCTION public.events_day(e public.events) OWNER TO graphql;

--
-- Name: events_day_index(public.events); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.events_day_index(e public.events) RETURNS smallint
    LANGUAGE sql STABLE
    AS $$
SELECT d.index AS day
FROM days d
WHERE d.conference_id = e.conference_id
  AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY day DESC
LIMIT 1;
$$;


ALTER FUNCTION public.events_day_index(e public.events) OWNER TO graphql;

--
-- Name: events_duration_time(public.events); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.events_duration_time(e public.events) RETURNS text
    LANGUAGE sql STABLE
    AS $$ SELECT to_char(e.duration, 'HH24:MI') $$;


ALTER FUNCTION public.events_duration_time(e public.events) OWNER TO graphql;

--
-- Name: events_persons(public.events, public.event_role[]); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.events_persons(e public.events, roles public.event_role[]) RETURNS SETOF public.people
    LANGUAGE sql STABLE
    AS $$
    SELECT p.* FROM people p, event_people ep
    WHERE e.id = ep.event_id AND ep.person_id = p.id AND ep.event_role IN( SELECT
            unnest( CASE WHEN roles IS NULL
                    THEN ARRAY['speaker', 'moderator']::event_role[]
                    ELSE roles
                END
            )::event_role
    )
$$;


ALTER FUNCTION public.events_persons(e public.events, roles public.event_role[]) OWNER TO graphql;

--
-- Name: events_room_name(public.events); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.events_room_name(e public.events) RETURNS text
    LANGUAGE sql STABLE
    AS $$
SELECT r.name
FROM rooms r
WHERE r.conference_id = e.conference_id
  AND r.id = e.room_id
$$;


ALTER FUNCTION public.events_room_name(e public.events) OWNER TO graphql;

--
-- Name: events_start_time(public.events); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.events_start_time(e public.events) RETURNS text
    LANGUAGE sql STABLE
    AS $$ SELECT to_char(e.start_date, 'HH24:MI') $$;


ALTER FUNCTION public.events_start_time(e public.events) OWNER TO graphql;

--
-- Name: send_change_event(); Type: FUNCTION; Schema: public; Owner: graphql
--

CREATE OR REPLACE FUNCTION public.send_change_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        notification json;
      BEGIN

        notification := json_build_object(
          'table', TG_TABLE_NAME,
          'action', TG_OP /*,
          'old', CASE WHEN OLD IS NOT NULL THEN row_to_json(OLD),
          'new', NEW AND row_to_json(NEW)*/
        );

        PERFORM pg_notify('change', notification::text);

        RETURN NULL;
      END;
    $$;


ALTER FUNCTION public.send_change_event() OWNER TO graphql;





--
-- Name: conferences conference_before_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER conference_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON public.conferences FOR EACH ROW EXECUTE PROCEDURE public.before_change();


--
-- Name: conferences conference_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER conference_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON public.conferences FOR EACH ROW EXECUTE PROCEDURE public.send_change_event();


--
-- Name: events event_before_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER event_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON public.events FOR EACH ROW EXECUTE PROCEDURE public.before_change();


--
-- Name: event_people event_before_person_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER event_before_person_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON public.event_people FOR EACH ROW EXECUTE PROCEDURE public.before_change();


--
-- Name: events event_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER event_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON public.events FOR EACH ROW EXECUTE PROCEDURE public.send_change_event();


--
-- Name: event_people event_person_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER event_person_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON public.event_people FOR EACH ROW EXECUTE PROCEDURE public.send_change_event();


--
-- Name: people person_before_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER person_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON public.people FOR EACH ROW EXECUTE PROCEDURE public.before_change();


--
-- Name: people person_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER person_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON public.people FOR EACH ROW EXECUTE PROCEDURE public.send_change_event();


--
-- Name: rooms room_before_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER room_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON public.rooms FOR EACH ROW EXECUTE PROCEDURE public.before_change();


--
-- Name: rooms room_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER room_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON public.rooms FOR EACH ROW EXECUTE PROCEDURE public.send_change_event();


--
-- Name: tracks track_before_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER track_before_change_event_trigger BEFORE INSERT OR DELETE OR UPDATE ON public.tracks FOR EACH ROW EXECUTE PROCEDURE public.before_change();


--
-- Name: tracks track_change_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER track_change_event_trigger AFTER INSERT OR DELETE OR UPDATE ON public.tracks FOR EACH ROW EXECUTE PROCEDURE public.send_change_event();


--
-- Name: conferences conferences_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conferences
    ADD CONSTRAINT conferences_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.conferences(id);


--
-- Name: days days_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days
    ADD CONSTRAINT days_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conferences(id);


--
-- Name: event_people event_people_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_people
    ADD CONSTRAINT event_people_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: event_people event_people_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_people
    ADD CONSTRAINT event_people_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.people(id);


--
-- Name: events events_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conferences(id);


--
-- Name: events events_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: events events_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id);


--
-- Name: rooms rooms_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conferences(id);


--
-- Name: tracks tracks_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conferences(id);


--
-- Name: versions versions_conference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_conference_id_fkey FOREIGN KEY (conference_id) REFERENCES public.conferences(id);


--
-- PostgreSQL database dump complete
--


GRANT SELECT ON TABLE conferences TO viewer;
GRANT SELECT ON TABLE days TO viewer;
GRANT SELECT ON TABLE events TO viewer;
GRANT SELECT ON TABLE event_people TO viewer;
GRANT SELECT ON TABLE people TO viewer;
GRANT SELECT ON TABLE rooms TO viewer;
GRANT SELECT ON TABLE tracks TO viewer;
GRANT SELECT ON TABLE languages TO viewer;
GRANT SELECT ON TABLE versions TO viewer;
