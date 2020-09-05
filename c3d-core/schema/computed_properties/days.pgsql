CREATE OR REPLACE FUNCTION days_date(d days) RETURNS date
    LANGUAGE sql STABLE
    AS $$ SELECT d.start_date::date $$;
ALTER FUNCTION days_date(d days) OWNER TO graphql;

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