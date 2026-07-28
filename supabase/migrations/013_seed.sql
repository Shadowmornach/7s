-- ============================================================
-- 7s TOMS — Migration 013: Seed Data
-- Owner account, default configuration, system places.
-- ============================================================

-- ============================================================
-- Default Configuration (Document 6 values)
-- ============================================================

INSERT INTO configuration (key, value, description) VALUES
    -- Authentication & OTP
    ('otp_expiry_minutes',              '5',        'OTP validity window in minutes (BR-001)'),
    ('otp_max_attempts',                '5',        'Max verification attempts per OTP (BR-001)'),
    ('otp_max_resends_per_hour',        '3',        'Max OTP resend requests per phone per hour (BR-001)'),
    ('otp_resend_cooldown_seconds',     '60',       'Minimum wait between resend requests (BR-001)'),

    -- Booking & Review
    ('restricted_booking_threshold',    '2',        'Strike count triggering Restricted Booking (BR-005)'),
    ('owner_review_timeout_seconds',    '180',      'Owner must act on queued request within this window (BR-007)'),
    ('fare_response_timeout_seconds',   '300',      'Passenger must accept/decline fare within this window (BR-007)'),
    ('rider_response_timeout_seconds',  '60',       'Assigned rider must accept/reject within this window (BR-008)'),
    ('duplicate_request_window_seconds','10',       'Same passenger + route within this window = duplicate (BR-030)'),
    ('stale_request_expiry_seconds',    '900',      'Hard max age for any non-terminal request in queues (BR-021)'),

    -- Service Area & Operating Hours
    ('service_center_lat',              '-3.3962',  'Center point latitude — Voi CBD (BR-018)'),
    ('service_center_lng',              '38.5561',  'Center point longitude — Voi CBD (BR-018)'),
    ('service_radius_km',              '20',        'Maximum distance from center for pickup/destination (BR-018)'),
    ('operating_hours_start',           '06:00',    'Daily operating hours start — EAT (BR-017)'),
    ('operating_hours_end',             '22:00',    'Daily operating hours end — EAT (BR-017)'),

    -- Payment
    ('mpesa_stk_timeout_seconds',       '90',       'Wait for Daraja callback before querying status (BR-010)'),
    ('mpesa_max_retries',               '3',        'Max STK push attempts per ride before forcing cash (BR-010)'),

    -- Ride Operations
    ('no_show_wait_seconds',            '300',      'Rider must wait at pickup before reporting no-show (BR-021)'),
    ('rating_window_hours',             '24',       'Hours after completion to submit a rating (BR-033)'),

    -- Share Ride
    ('share_endpoint_rate_limit',       '60',       'Public endpoint rate limit — req/min/IP (BR-013)'),
    ('share_poll_interval_seconds',     '10',       'Recommended client poll interval — advisory (BR-013)'),

    -- Rate Limiting
    ('ride_requests_per_hour',          '5',        'Max ride requests per passenger per hour (NFR §2)'),

    -- Business Identity
    ('business_name',                   '7s Transport', 'Display name shown to passengers');

-- ============================================================
-- System Places (Voi landmarks)
-- Owner will customize these — these are reasonable starting points
-- ============================================================

-- Note: These INSERTs require an owner user to exist first.
-- In production, the owner account is created during Supabase Auth setup.
-- For development, create a placeholder owner first:

-- DO block to seed owner, verified riders, Voi landmarks, and fare templates
DO $$
DECLARE
    owner_id UUID;
    rider2_id UUID;
    p_cbd UUID;
    p_sgr UUID;
    p_hosp UUID;
    p_mwatate UUID;
    p_mkt UUID;
BEGIN
    -- 1. Owner account & rider profile
    INSERT INTO users (phone_number, role, full_name, status)
    VALUES ('+254700000000', 'OWNER', '7s Owner', 'ACTIVE')
    ON CONFLICT (phone_number) DO UPDATE SET full_name = EXCLUDED.full_name
    RETURNING id INTO owner_id;

    INSERT INTO riders (id, motorcycle_plate, id_verified, is_online)
    VALUES (owner_id, 'KMXX 001A', true, false)
    ON CONFLICT (id) DO UPDATE SET id_verified = true;

    -- 2. Additional verified rider account
    INSERT INTO users (phone_number, role, full_name, status)
    VALUES ('+254711000111', 'RIDER', 'Juma Bakari (Rider 2)', 'ACTIVE')
    ON CONFLICT (phone_number) DO UPDATE SET full_name = EXCLUDED.full_name
    RETURNING id INTO rider2_id;

    INSERT INTO riders (id, motorcycle_plate, id_verified, is_online)
    VALUES (rider2_id, 'KMXX 002B', true, false)
    ON CONFLICT (id) DO UPDATE SET id_verified = true;

    -- 3. System Places (Voi landmarks)
    INSERT INTO places (name, latitude, longitude, place_type, origin, created_by)
    VALUES ('Voi CBD', -3.3962, 38.5561, 'SYSTEM', 'MANUAL', owner_id)
    RETURNING id INTO p_cbd;

    INSERT INTO places (name, latitude, longitude, place_type, origin, created_by)
    VALUES ('Voi SGR Station', -3.3708, 38.5598, 'SYSTEM', 'MANUAL', owner_id)
    RETURNING id INTO p_sgr;

    INSERT INTO places (name, latitude, longitude, place_type, origin, created_by)
    VALUES ('Voi Hospital', -3.3885, 38.5637, 'SYSTEM', 'MANUAL', owner_id)
    RETURNING id INTO p_hosp;

    INSERT INTO places (name, latitude, longitude, place_type, origin, created_by)
    VALUES ('Mwatate Junction', -3.5050, 38.3734, 'SYSTEM', 'MANUAL', owner_id)
    RETURNING id INTO p_mwatate;

    INSERT INTO places (name, latitude, longitude, place_type, origin, created_by)
    VALUES ('Voi Market', -3.3948, 38.5569, 'SYSTEM', 'MANUAL', owner_id)
    RETURNING id INTO p_mkt;

    -- 4. Fare Templates for common Voi routes
    INSERT INTO fare_templates (from_place_id, to_place_id, fare, estimated_distance, estimated_time, active, notes)
    VALUES
        (p_cbd, p_sgr, 150.00, 5.5, 600, true, 'Voi CBD to Voi SGR Station'),
        (p_sgr, p_cbd, 150.00, 5.5, 600, true, 'Voi SGR Station to Voi CBD'),
        (p_cbd, p_hosp, 100.00, 2.0, 300, true, 'Voi CBD to Voi Hospital'),
        (p_hosp, p_cbd, 100.00, 2.0, 300, true, 'Voi Hospital to Voi CBD'),
        (p_cbd, p_mkt, 80.00, 1.0, 180, true, 'Voi CBD to Voi Market'),
        (p_mkt, p_cbd, 80.00, 1.0, 180, true, 'Voi Market to Voi CBD'),
        (p_cbd, p_mwatate, 300.00, 15.0, 1200, true, 'Voi CBD to Mwatate Junction'),
        (p_mwatate, p_cbd, 300.00, 15.0, 1200, true, 'Mwatate Junction to Voi CBD'),
        (p_sgr, p_hosp, 200.00, 6.0, 720, true, 'Voi SGR Station to Voi Hospital'),
        (p_hosp, p_sgr, 200.00, 6.0, 720, true, 'Voi Hospital to Voi SGR Station');
END $$;

