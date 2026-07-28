-- ============================================================
-- 7s TOMS — Migration 020: Telemetry Support
-- Inbound location updates for riders. Document 4 §5.
-- ============================================================

-- Alter type to add TELEMETRY_UPDATE if not exists
-- PostgreSQL requires running ALTER TYPE ADD VALUE outside transaction blocks or safely
-- Since Supabase migrations are separate, it is safe to run.
ALTER TYPE ride_event_type ADD VALUE 'TELEMETRY_UPDATE';

-- Add trigger to update riders table when location is supplied
CREATE OR REPLACE FUNCTION trg_ride_events_update_rider_location()
RETURNS TRIGGER AS $$
DECLARE
    r_id UUID;
BEGIN
    IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
        -- Get the rider_id for the ride
        SELECT rider_id INTO r_id FROM rides WHERE id = NEW.ride_id;
        
        -- Update rider's current location and last updated timestamp
        IF r_id IS NOT NULL THEN
            UPDATE riders
            SET current_lat = NEW.lat,
                current_lng = NEW.lng,
                last_location_at = NEW.created_at
            WHERE id = r_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_ride_events_after_insert_location
    AFTER INSERT ON ride_events
    FOR EACH ROW
    EXECUTE FUNCTION trg_ride_events_update_rider_location();
