--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.10

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
-- Name: postgraphile_watch; Type: SCHEMA; Schema: -; Owner: andi
--

CREATE SCHEMA postgraphile_watch;


ALTER SCHEMA postgraphile_watch OWNER TO andi;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: event_role; Type: TYPE; Schema: public; Owner: andi
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


ALTER TYPE public.event_role OWNER TO andi;

--
-- Name: gender; Type: TYPE; Schema: public; Owner: andi
--

CREATE TYPE public.gender AS ENUM (
    'MALE',
    'FEMALE',
    'OTHER'
);


ALTER TYPE public.gender OWNER TO andi;

--
-- Name: link; Type: TYPE; Schema: public; Owner: andi
--

CREATE TYPE public.link AS (
	title text,
	url text
);


ALTER TYPE public.link OWNER TO andi;

--
-- Name: notify_watchers_ddl(); Type: FUNCTION; Schema: postgraphile_watch; Owner: andi
--

CREATE FUNCTION postgraphile_watch.notify_watchers_ddl() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION postgraphile_watch.notify_watchers_ddl() OWNER TO andi;

--
-- Name: notify_watchers_drop(); Type: FUNCTION; Schema: postgraphile_watch; Owner: andi
--

CREATE FUNCTION postgraphile_watch.notify_watchers_drop() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION postgraphile_watch.notify_watchers_drop() OWNER TO andi;

--
-- Name: before_change(); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.before_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      DECLARE
        notification json;
      BEGIN
        NEW.updated_at = now();

        RETURN NEW;
      END;
    $$;


ALTER FUNCTION public.before_change() OWNER TO andi;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: days; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.days (
    id bigint NOT NULL,
    conference_id bigint,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    index smallint
);


ALTER TABLE public.days OWNER TO postgres;

--
-- Name: days_date(public.days); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.days_date(d public.days) RETURNS date
    LANGUAGE sql STABLE
    AS $$ SELECT d.start_date::date $$;


ALTER FUNCTION public.days_date(d public.days) OWNER TO andi;

--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id bigint NOT NULL,
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
    updated_at timestamp with time zone NOT NULL,
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


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: days_events(public.days); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.days_events(d public.days) RETURNS public.events
    LANGUAGE sql STABLE
    AS $$
SELECT e.* 
FROM events e
WHERE d.conference_id = e.conference_id
	AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY e.start_date;
$$;


ALTER FUNCTION public.days_events(d public.days) OWNER TO andi;

--
-- Name: events_day(public.events); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.events_day(e public.events) RETURNS public.days
    LANGUAGE sql STABLE
    AS $$
SELECT d.* 
FROM days d
WHERE d.conference_id = e.conference_id
  AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY d.index DESC
LIMIT 1;
$$;


ALTER FUNCTION public.events_day(e public.events) OWNER TO andi;

--
-- Name: events_day_index(public.events); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.events_day_index(e public.events) RETURNS smallint
    LANGUAGE sql STABLE
    AS $$
SELECT d.index AS day 
FROM days d
WHERE d.conference_id = e.conference_id
  AND e.start_date BETWEEN d.start_date AND d.end_date
ORDER BY day DESC
LIMIT 1;
$$;


ALTER FUNCTION public.events_day_index(e public.events) OWNER TO andi;

--
-- Name: events_duration_time(public.events); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.events_duration_time(e public.events) RETURNS text
    LANGUAGE sql STABLE
    AS $$ SELECT to_char(e.duration, 'HH24:MI') $$;


ALTER FUNCTION public.events_duration_time(e public.events) OWNER TO andi;

--
-- Name: people; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.people (
    id bigint NOT NULL,
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
    updated_at timestamp with time zone NOT NULL,
    user_id integer,
    note text,
    include_in_mailings boolean DEFAULT false NOT NULL,
    use_gravatar boolean DEFAULT false NOT NULL
);


ALTER TABLE public.people OWNER TO postgres;

--
-- Name: events_persons(public.events, public.event_role[]); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.events_persons(e public.events, roles public.event_role[]) RETURNS SETOF public.people
    LANGUAGE sql STABLE
    AS $$
	SELECT p.* FROM people p, event_people ep
	WHERE e.id = ep.event_id AND ep.person_id = p.id AND ep.event_role IN( SELECT 
		CASE WHEN roles IS NULL 
			THEN unnest(ARRAY['speaker', 'moderator'])::event_role
			ELSE unnest(roles)
		END
	)
$$;


ALTER FUNCTION public.events_persons(e public.events, roles public.event_role[]) OWNER TO andi;

--
-- Name: events_room_name(public.events); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.events_room_name(e public.events) RETURNS text
    LANGUAGE sql STABLE
    AS $$
SELECT r.name 
FROM rooms r
WHERE r.conference_id = e.conference_id
  AND r.id = e.room_id
$$;


ALTER FUNCTION public.events_room_name(e public.events) OWNER TO andi;

--
-- Name: events_start_time(public.events); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.events_start_time(e public.events) RETURNS text
    LANGUAGE sql STABLE
    AS $$ SELECT to_char(e.start_date, 'HH24:MI') $$;


ALTER FUNCTION public.events_start_time(e public.events) OWNER TO andi;

--
-- Name: send_change_event(); Type: FUNCTION; Schema: public; Owner: andi
--

CREATE FUNCTION public.send_change_event() RETURNS trigger
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


ALTER FUNCTION public.send_change_event() OWNER TO andi;

--
-- Name: conferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conferences (
    id bigint NOT NULL,
    acronym character varying(255) NOT NULL,
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
    end_date timestamp with time zone
);


ALTER TABLE public.conferences OWNER TO postgres;

--
-- Name: conferences_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.conferences_id_seq OWNER TO postgres;

--
-- Name: conferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conferences_id_seq OWNED BY public.conferences.id;


--
-- Name: days_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.days_id_seq OWNER TO postgres;

--
-- Name: days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.days_id_seq OWNED BY public.days.id;


--
-- Name: event_people; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_people (
    id bigint NOT NULL,
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


ALTER TABLE public.event_people OWNER TO postgres;

--
-- Name: event_people_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.event_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.event_people_id_seq OWNER TO postgres;

--
-- Name: event_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.event_people_id_seq OWNED BY public.event_people.id;


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.events_id_seq OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.languages (
    id bigint NOT NULL,
    code character varying(255),
    attachable_id integer,
    attachable_type character varying(255),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.languages OWNER TO postgres;

--
-- Name: languages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.languages_id_seq OWNER TO postgres;

--
-- Name: languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.languages_id_seq OWNED BY public.languages.id;


--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.people_id_seq OWNER TO postgres;

--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.people_id_seq OWNED BY public.people.id;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rooms (
    id bigint NOT NULL,
    conference_id integer NOT NULL,
    name character varying(255) NOT NULL,
    size integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    rank integer
);


ALTER TABLE public.rooms OWNER TO postgres;

--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rooms_id_seq OWNER TO postgres;

--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rooms_id_seq OWNED BY public.rooms.id;


--
-- Name: tracks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tracks (
    id bigint NOT NULL,
    conference_id integer,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT '2018-10-07 14:06:49.211567'::timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    color character varying(255) DEFAULT 'fefd7f'::character varying
);


ALTER TABLE public.tracks OWNER TO postgres;

--
-- Name: tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tracks_id_seq OWNER TO postgres;

--
-- Name: tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tracks_id_seq OWNED BY public.tracks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
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
    updated_at timestamp without time zone NOT NULL,
    role character varying(255) DEFAULT 'submitter'::character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id integer NOT NULL,
    event character varying(255) NOT NULL,
    whodunnit character varying(255),
    object text,
    created_at timestamp with time zone,
    conference_id integer,
    associated_id integer,
    associated_type character varying(255),
    object_changes text
);


ALTER TABLE public.versions OWNER TO postgres;

--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.versions_id_seq OWNER TO postgres;

--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: conferences id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conferences ALTER COLUMN id SET DEFAULT nextval('public.conferences_id_seq'::regclass);


--
-- Name: days id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.days ALTER COLUMN id SET DEFAULT nextval('public.days_id_seq'::regclass);


--
-- Name: event_people id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_people ALTER COLUMN id SET DEFAULT nextval('public.event_people_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: languages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.languages ALTER COLUMN id SET DEFAULT nextval('public.languages_id_seq'::regclass);


--
-- Name: people id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people ALTER COLUMN id SET DEFAULT nextval('public.people_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rooms ALTER COLUMN id SET DEFAULT nextval('public.rooms_id_seq'::regclass);


--
-- Name: tracks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks ALTER COLUMN id SET DEFAULT nextval('public.tracks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Data for Name: conferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conferences (id, acronym, title, timezone, feedback_enabled, created_at, updated_at, email, program_export_base_url, schedule_version, schedule_public, color, default_recording_license, parent_id, logo, start_date, end_date) FROM stdin;
4	geekend2018	Geekend Q4 2018 adfas	Berlin	f	2018-10-07 12:09:36.208968+02	2018-10-07 12:09:36.208968+02	\N	\N	\N	f	\N	\N	\N	\N	2018-10-06 00:00:00+02	2018-10-06 00:00:00+02
1	test3	Foo Conferencefoofoo foo foofoo	Berlin	f	2018-10-07 12:05:04.051653+02	2018-10-07 13:01:33.765192+02	\N	\N	\N	f	\N	\N	\N	\N	\N	\N
\.


--
-- Name: conferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.conferences_id_seq', 6, true);


--
-- Data for Name: days; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.days (id, conference_id, start_date, end_date, index) FROM stdin;
2	4	2018-10-06 10:00:00+02	2018-10-07 03:00:00+02	1
\.


--
-- Name: days_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.days_id_seq', 2, true);


--
-- Data for Name: event_people; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.event_people (id, event_id, person_id, event_role, role_state, comment, created_at, updated_at, confirmation_token, notification_subject, notification_body) FROM stdin;
3	1	2	speaker	\N	\N	2018-10-07 15:44:36.415521+02	2018-10-07 15:45:03.187973+02	\N	\N	\N
4	2	3	speaker	\N	\N	2018-10-07 15:44:36.415521+02	2018-10-07 15:45:03.187973+02	\N	\N	\N
\.


--
-- Name: event_people_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.event_people_id_seq', 4, true);


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.events (id, conference_id, title, subtitle, event_type, slug, state, language, start_date, abstract, description, public, logo, track_id, room_id, created_at, updated_at, average_rating, event_ratings_count, note, guid, do_not_record, recording_license, tech_rider, links, attachments, duration, local_id) FROM stdin;
2	4	How to RELIVE	\N	talk	geekend2018-2-how_to_relive	new	de	2018-10-06 22:10:00+02	\N	\N	t	\N	\N	3	2018-10-07 14:15:58.717243+02	2018-10-07 15:31:05.207378+02	\N	0	\N	4e876909-16b1-5520-82a8-07f257a20faf	f	\N	\N	\N	\N	00:15:00	2
1	4	(W)o (i)st mei(n)e Winke(k)atze?	\N	talk	geekend2018-1-w_o_i_st_mei_n_e_winke_k_atze	new	de	2018-10-06 22:00:00+02	\N	\N	t	\N	\N	3	2018-10-07 14:11:53.231824+02	2018-10-07 15:31:05.207378+02	\N	0	\N	6f3f49b6-2f08-50ff-a45c-aa728047dd5e	f	\N	\N	\N	\N	00:15:00	1
5	1	tst	\N	talk	ddd	new	\N	2018-10-07 14:15:58.717243+02	\N	\N	t	\N	\N	\N	2018-10-07 15:20:27.885291+02	2018-10-07 15:31:05.207378+02	\N	0	\N	4e876909-16b1-5520-82a8-07f257a20faa	f	\N	\N	\N	\N	00:15:00	1
\.


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.events_id_seq', 5, true);


--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.languages (id, code, attachable_id, attachable_type, created_at, updated_at) FROM stdin;
\.


--
-- Name: languages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.languages_id_seq', 1, false);


--
-- Data for Name: people; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.people (id, first_name, last_name, public_name, email, email_public, gender, avatar, abstract, description, created_at, updated_at, user_id, note, include_in_mailings, use_gravatar) FROM stdin;
1	admin	admin	admin_127	admin@example.org	t	\N	\N	\N	\N	2018-10-07 08:48:56.219843+02	2018-10-07 08:48:56.403675+02	1	\N	f	f
2			meise	\N	t	\N	\N	\N	\N	2018-10-07 15:36:10.495535+02	2018-10-07 15:36:10.495535+02	\N	\N	f	f
3			florolf	\N	t	\N	\N	\N	\N	2018-10-07 15:36:19.15047+02	2018-10-07 15:36:19.15047+02	\N	\N	f	f
\.


--
-- Name: people_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.people_id_seq', 3, true);


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rooms (id, conference_id, name, size, created_at, updated_at, rank) FROM stdin;
3	4	CCCB	\N	2018-10-07 14:09:14.363768+02	2018-10-07 14:09:14.363768+02	\N
\.


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rooms_id_seq', 3, true);


--
-- Data for Name: tracks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tracks (id, conference_id, name, created_at, updated_at, color) FROM stdin;
\.


--
-- Name: tracks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tracks_id_seq', 1, false);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, reset_password_token, remember_created_at, remember_token, sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, confirmation_token, confirmed_at, confirmation_sent_at, created_at, updated_at, role, encrypted_password, reset_password_sent_at, unconfirmed_email, failed_attempts, unlock_token, locked_at) FROM stdin;
1	admin@example.org	\N	\N	\N	0	\N	\N	\N	\N	\N	2018-10-07 08:48:56.38481	\N	2018-10-07 08:48:56.400848	2018-10-07 08:48:56.400848	admin	$2a$11$MXZtj8J/INPsMT.rZ1nqVuQoFB2yXWDFBMlkbKIWgZyQGLJFd8yXO	\N	\N	0	\N	\N
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Data for Name: versions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.versions (id, item_type, item_id, event, whodunnit, object, created_at, conference_id, associated_id, associated_type, object_changes) FROM stdin;
\.


--
-- Name: versions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.versions_id_seq', 1, false);


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
-- Name: postgraphile_watch_ddl; Type: EVENT TRIGGER; Schema: -; Owner: andi
--

CREATE EVENT TRIGGER postgraphile_watch_ddl ON ddl_command_end
         WHEN TAG IN ('ALTER AGGREGATE', 'ALTER DOMAIN', 'ALTER EXTENSION', 'ALTER FOREIGN TABLE', 'ALTER FUNCTION', 'ALTER POLICY', 'ALTER SCHEMA', 'ALTER TABLE', 'ALTER TYPE', 'ALTER VIEW', 'COMMENT', 'CREATE AGGREGATE', 'CREATE DOMAIN', 'CREATE EXTENSION', 'CREATE FOREIGN TABLE', 'CREATE FUNCTION', 'CREATE INDEX', 'CREATE POLICY', 'CREATE RULE', 'CREATE SCHEMA', 'CREATE TABLE', 'CREATE TABLE AS', 'CREATE VIEW', 'DROP AGGREGATE', 'DROP DOMAIN', 'DROP EXTENSION', 'DROP FOREIGN TABLE', 'DROP FUNCTION', 'DROP INDEX', 'DROP OWNED', 'DROP POLICY', 'DROP RULE', 'DROP SCHEMA', 'DROP TABLE', 'DROP TYPE', 'DROP VIEW', 'GRANT', 'REVOKE', 'SELECT INTO')
   EXECUTE PROCEDURE postgraphile_watch.notify_watchers_ddl();


ALTER EVENT TRIGGER postgraphile_watch_ddl OWNER TO andi;

--
-- Name: postgraphile_watch_drop; Type: EVENT TRIGGER; Schema: -; Owner: andi
--

CREATE EVENT TRIGGER postgraphile_watch_drop ON sql_drop
   EXECUTE PROCEDURE postgraphile_watch.notify_watchers_drop();


ALTER EVENT TRIGGER postgraphile_watch_drop OWNER TO andi;

--
-- PostgreSQL database dump complete
--

