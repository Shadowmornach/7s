-- ============================================================
-- 7s TOMS — Migration 009: Indexes
-- Per Document 5 §3 (Scalability).
-- ============================================================

-- Rides — every dashboard query filters on these
CREATE INDEX idx_rides_status ON rides(status);
CREATE INDEX idx_rides_passenger_id ON rides(passenger_id);
CREATE INDEX idx_rides_rider_id ON rides(rider_id);
CREATE INDEX idx_rides_created_at ON rides(created_at);
CREATE INDEX idx_rides_payment_status ON rides(payment_status);
CREATE INDEX idx_rides_share_token ON rides(share_token) WHERE share_token IS NOT NULL;

-- Composite: active rides per passenger (BR-027 check)
CREATE UNIQUE INDEX idx_rides_passenger_active_uq ON rides(passenger_id)
    WHERE status NOT IN ('COMPLETED', 'CANCELLED');

-- Composite: active rides per rider (BR-026 check)
CREATE UNIQUE INDEX idx_rides_rider_active_uq ON rides(rider_id)
    WHERE rider_id IS NOT NULL AND status NOT IN ('COMPLETED', 'CANCELLED');

-- Ride Events — ordered by sequence for ride timeline
CREATE INDEX idx_ride_events_ride_id ON ride_events(ride_id, sequence_number);
CREATE INDEX idx_ride_events_type ON ride_events(ride_event_type);

-- Payment Events — per ride timeline
CREATE INDEX idx_payment_events_ride_id ON payment_events(ride_id, sequence_number);

-- SOS Alerts — active alerts first, then by severity
CREATE INDEX idx_sos_alerts_status ON sos_alerts(status, severity, created_at);
CREATE INDEX idx_sos_alerts_ride_id ON sos_alerts(ride_id);

-- Places — active places for selection queries
CREATE INDEX idx_places_active_type ON places(place_type, active) WHERE active = true;
CREATE INDEX idx_places_created_by ON places(created_by);

-- Fare Templates — active template lookup
CREATE INDEX idx_fare_templates_active ON fare_templates(from_place_id, to_place_id)
    WHERE active = true;

-- Riders — online riders for assignment
CREATE INDEX idx_riders_online ON riders(is_online) WHERE is_online = true;

-- Cash Handovers — per rider history
CREATE INDEX idx_cash_handovers_rider ON cash_handovers(rider_id, created_at);

-- Ratings — per ride and per rated user
CREATE INDEX idx_ratings_ride ON ratings(ride_id);
CREATE INDEX idx_ratings_rated_user ON ratings(rated_user);
