DROP FUNCTION IF EXISTS send_change_event() CASCADE;

CREATE OR REPLACE FUNCTION send_change_event() RETURNS TRIGGER AS $$
  DECLARE
    notification json;
  BEGIN
    notification := json_build_object(
      'table', TG_TABLE_NAME,
      'action', TG_OP,
      'old', CASE WHEN TG_OP <> 'INSERT' THEN row_to_json(OLD)::jsonb - 'streaming_config' END,
      'new', CASE WHEN TG_OP <> 'DELETE' THEN row_to_json(NEW)::jsonb - 'streaming_config' END
    );
    PERFORM pg_notify('change', notification::text);
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER conference_change_event_trigger   AFTER INSERT OR UPDATE OR DELETE ON conferences  FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER event_change_event_trigger 		   AFTER INSERT OR UPDATE OR DELETE ON events 	    FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER person_change_event_trigger 		   AFTER INSERT OR UPDATE OR DELETE ON people 	    FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER event_person_change_event_trigger AFTER INSERT OR UPDATE OR DELETE ON event_people FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER track_change_event_trigger 		   AFTER INSERT OR UPDATE OR DELETE ON tracks 	    FOR EACH ROW EXECUTE PROCEDURE send_change_event();
CREATE TRIGGER room_change_event_trigger 		     AFTER INSERT OR UPDATE OR DELETE ON rooms 		    FOR EACH ROW EXECUTE PROCEDURE send_change_event();