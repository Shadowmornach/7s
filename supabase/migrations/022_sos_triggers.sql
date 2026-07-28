-- SQL Migration: 022_sos_triggers.sql
-- Automate inserting and updating of sos_alerts based on ride_events

CREATE OR REPLACE FUNCTION trg_ride_events_insert_sos_alert_func()
RETURNS TRIGGER AS $$
DECLARE
    v_severity sos_severity;
BEGIN
    IF NEW.ride_event_type = 'SOS_TRIGGERED' THEN
        -- Map severity text to enum safely
        BEGIN
            v_severity := COALESCE((NEW.metadata->>'severity')::sos_severity, 'CRITICAL'::sos_severity);
        EXCEPTION WHEN OTHERS THEN
            v_severity := 'CRITICAL'::sos_severity;
        END;

        INSERT INTO sos_alerts (ride_id, triggered_by, lat, lng, severity, emergency_type, status)
        VALUES (
            NEW.ride_id,
            NEW.actor_id,
            COALESCE(NEW.lat, 0.0),
            COALESCE(NEW.lng, 0.0),
            v_severity,
            COALESCE(NEW.metadata->>'emergency_type', 'Other'),
            'ACTIVE'
        );
    ELSIF NEW.ride_event_type = 'SOS_RESOLVED' THEN
        UPDATE sos_alerts
        SET status = 'RESOLVED',
            resolved_at = now(),
            resolved_by = NEW.actor_id,
            resolution_notes = COALESCE(NEW.metadata->>'resolution_notes', 'Resolved via event')
        WHERE ride_id = NEW.ride_id AND status = 'ACTIVE';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ride_events_insert_sos_alert
AFTER INSERT ON ride_events
FOR EACH ROW
EXECUTE FUNCTION trg_ride_events_insert_sos_alert_func();
