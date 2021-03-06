CREATE OR REPLACE FUNCTION events_persons(e events, roles event_role[])
 RETURNS SETOF people
 LANGUAGE sql STABLE
AS $$
  SELECT p.* FROM people p, event_people ep
  WHERE e.guid = ep.event_id AND ep.person_guid = p.guid AND ep.event_role IN( 
    SELECT
      unnest( CASE WHEN roles IS NULL
        THEN ARRAY['speaker', 'moderator']::event_role[]
        ELSE roles
      END
    )::event_role
  )
$$;
ALTER FUNCTION events_persons(e events, roles event_role[]) OWNER TO graphql;


CREATE OR REPLACE FUNCTION events_day(e events) 
 RETURNS days
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

CREATE OR REPLACE FUNCTION events_day_index(e events) 
 RETURNS smallint
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

CREATE OR REPLACE FUNCTION events_duration_time(e events) RETURNS text
 LANGUAGE sql STABLE
AS $$ SELECT to_char(e.duration, 'HH24:MI') $$;
ALTER FUNCTION events_duration_time(e events) OWNER TO graphql;


CREATE OR REPLACE FUNCTION events_room_name(e events) 
 RETURNS text
 LANGUAGE sql STABLE
AS $$
  SELECT r.name 
  FROM rooms r
  WHERE r.conference_id = e.conference_id
    AND r.guid = e.room_id
$$;
ALTER FUNCTION events_room_name(e events) OWNER TO graphql;

CREATE OR REPLACE FUNCTION events_start_time(e events) RETURNS text
  LANGUAGE sql STABLE
AS $$ SELECT to_char(e.start_date, 'HH24:MI') $$;
ALTER FUNCTION events_start_time(e events) OWNER TO graphql;
