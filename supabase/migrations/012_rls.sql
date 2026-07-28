-- ============================================================
-- 7s TOMS — Migration 012: Row Level Security
-- Supabase RLS as second line of defense (NFR §1).
-- Primary gate is FastAPI; RLS is the backstop.
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE riders ENABLE ROW LEVEL SECURITY;
ALTER TABLE passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE fare_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE ride_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE sos_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_handovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuration ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- USERS
-- ============================================================

-- Users can read their own profile
CREATE POLICY users_select_own ON users
    FOR SELECT USING (auth.uid() = id);

-- Owner can read all users
CREATE POLICY users_select_owner ON users
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- PLACES (BR-014)
-- ============================================================

-- SYSTEM and OWNER places: globally readable
CREATE POLICY places_select_public ON places
    FOR SELECT USING (place_type IN ('SYSTEM', 'OWNER'));

-- USER places: only visible to their creator
CREATE POLICY places_select_own ON places
    FOR SELECT USING (place_type = 'USER' AND created_by = auth.uid());

-- Owner can see all places (for management)
CREATE POLICY places_select_owner ON places
    FOR SELECT USING (
        place_type IN ('SYSTEM', 'OWNER') AND
        auth.jwt() ->> 'role' = 'owner'
    );

-- Only owner can create/update SYSTEM and OWNER places
CREATE POLICY places_insert_owner ON places
    FOR INSERT WITH CHECK (
        (place_type IN ('SYSTEM', 'OWNER') AND auth.jwt() ->> 'role' = 'owner')
        OR (place_type = 'USER' AND created_by = auth.uid())
    );

-- ============================================================
-- RIDES
-- ============================================================

-- Passenger can see their own rides
CREATE POLICY rides_select_passenger ON rides
    FOR SELECT USING (passenger_id = auth.uid());

-- Rider can see their assigned rides
CREATE POLICY rides_select_rider ON rides
    FOR SELECT USING (rider_id = auth.uid());

-- Owner can see all rides
CREATE POLICY rides_select_owner ON rides
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- RIDE EVENTS (read-only via RLS; writes via service role only)
-- ============================================================

-- Participants can read events for their rides
CREATE POLICY ride_events_select ON ride_events
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM rides r
            WHERE r.id = ride_events.ride_id
            AND (r.passenger_id = auth.uid() OR r.rider_id = auth.uid())
        )
    );

-- Owner can read all events
CREATE POLICY ride_events_select_owner ON ride_events
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- PAYMENT EVENTS (read-only via RLS; writes via service role only)
-- ============================================================

CREATE POLICY payment_events_select ON payment_events
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM rides r
            WHERE r.id = payment_events.ride_id
            AND (r.passenger_id = auth.uid() OR r.rider_id = auth.uid())
        )
    );

CREATE POLICY payment_events_select_owner ON payment_events
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- SOS ALERTS
-- ============================================================

-- Participants can see SOS for their rides
CREATE POLICY sos_select ON sos_alerts
    FOR SELECT USING (
        triggered_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM rides r
            WHERE r.id = sos_alerts.ride_id
            AND (r.passenger_id = auth.uid() OR r.rider_id = auth.uid())
        )
    );

-- Owner can see all
CREATE POLICY sos_select_owner ON sos_alerts
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- CONFIGURATION (owner-only read/write)
-- ============================================================

CREATE POLICY config_select_owner ON configuration
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );

CREATE POLICY config_update_owner ON configuration
    FOR UPDATE USING (
        auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- FARE TEMPLATES (readable by all, writable by owner)
-- ============================================================

CREATE POLICY fare_templates_select ON fare_templates
    FOR SELECT USING (active = true);

CREATE POLICY fare_templates_select_owner ON fare_templates
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- CASH HANDOVERS (owner + involved rider)
-- ============================================================

CREATE POLICY cash_handovers_select ON cash_handovers
    FOR SELECT USING (
        rider_id = auth.uid()
        OR auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- RATINGS
-- ============================================================

CREATE POLICY ratings_select ON ratings
    FOR SELECT USING (
        rated_by = auth.uid()
        OR rated_user = auth.uid()
        OR auth.jwt() ->> 'role' = 'owner'
    );

-- ============================================================
-- PAYMENT ACCOUNTS (owner-only)
-- ============================================================

CREATE POLICY payment_accounts_select_owner ON payment_accounts
    FOR SELECT USING (
        auth.jwt() ->> 'role' = 'owner'
    );
