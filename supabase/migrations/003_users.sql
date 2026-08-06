-- ============================================================
-- 7s TOMS — Migration 003: Users, Riders, Passengers
-- Core identity tables. BR-001, BR-002, BR-003.
-- ============================================================

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number    VARCHAR(20) NOT NULL UNIQUE,
    role            user_role NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    photo_url       TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT false,
    is_suspended    BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE users IS 'All users: owner, riders, passengers. One table + role-specific extensions.';
COMMENT ON COLUMN users.phone_number IS 'Optional M-Pesa payment MSISDN. Format: 0712xxxxxx / 2547...';
COMMENT ON COLUMN users.role IS 'Server-side claim, never inferred client-side (BR-002).';
COMMENT ON COLUMN users.is_suspended IS 'Suspended users cannot create rides or go online (BR-004).';

-- Role-specific extension: Riders
CREATE TABLE riders (
    id                  UUID PRIMARY KEY REFERENCES users(id) ON DELETE RESTRICT,
    motorcycle_plate    VARCHAR(20) NOT NULL,
    motorcycle_model    VARCHAR(100),
    license_number      VARCHAR(50),
    id_verified         BOOLEAN NOT NULL DEFAULT false,
    is_online           BOOLEAN NOT NULL DEFAULT false,
    current_lat         DECIMAL(10, 7),
    current_lng         DECIMAL(10, 7),
    last_location_at    TIMESTAMPTZ,
    strike_count        INTEGER NOT NULL DEFAULT 0,

    -- BR-003: Cannot go online unless id_verified and not suspended
    -- Enforced at application layer (requires join to users.is_suspended)
    CONSTRAINT chk_rider_online_verified CHECK (
        is_online = false
        OR id_verified = true
    )
);

COMMENT ON TABLE riders IS 'Rider-specific data. Extends users where role = RIDER.';
COMMENT ON COLUMN riders.id_verified IS 'Must be true before rider can go online (BR-003).';
COMMENT ON COLUMN riders.is_online IS 'Online/offline toggle. Controls assignment eligibility.';

-- Role-specific extension: Passengers
CREATE TABLE passengers (
    id              UUID PRIMARY KEY REFERENCES users(id) ON DELETE RESTRICT,
    strike_count    INTEGER NOT NULL DEFAULT 0
);

COMMENT ON TABLE passengers IS 'Passenger-specific data. Extends users where role = PASSENGER.';
COMMENT ON COLUMN passengers.strike_count IS 'Feeds Restricted Booking check (BR-005, BR-019). Incremented by owner only (BR-004).';
