CREATE OR REPLACE FUNCTION days_date(d days) RETURNS date
 LANGUAGE sql
 STABLE
AS $$ SELECT d.start_date::date $$;

