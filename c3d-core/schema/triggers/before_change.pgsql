DROP FUNCTION IF EXISTS before_change() CASCADE;

CREATE OR REPLACE FUNCTION before_change() RETURNS TRIGGER AS $$
  DECLARE
    notification json;
  BEGIN
    NEW.updated_at = now();

    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER conference_before_change_event_trigger    BEFORE INSERT OR UPDATE OR DELETE ON conferences  FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER event_before_change_event_trigger 		     BEFORE INSERT OR UPDATE OR DELETE ON events 	     FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER person_before_change_event_trigger 		   BEFORE INSERT OR UPDATE OR DELETE ON people 	     FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER event_before_person_change_event_trigger  BEFORE INSERT OR UPDATE OR DELETE ON event_people FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER track_before_change_event_trigger 		     BEFORE INSERT OR UPDATE OR DELETE ON tracks  	   FOR EACH ROW EXECUTE PROCEDURE before_change();
CREATE TRIGGER room_before_change_event_trigger 		     BEFORE INSERT OR UPDATE OR DELETE ON rooms 	     FOR EACH ROW EXECUTE PROCEDURE before_change();