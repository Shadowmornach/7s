-- ============================================================
-- 7s TOMS — Migration 006: Rides
-- The core transaction table. BR-009, BR-010, BR-029.
-- ============================================================

CREATE TABLE payment_accounts (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider                VARCHAR(50) NOT NULL,  -- MPESA_TILL, MPESA_PAYBILL, MPESA_PERSONAL
    display_name            VARCHAR(255) NOT NULL,  -- shown to passengers, never raw owner phone
    till_paybill_or_number  VARCHAR(50) NOT NULL,
    is_default              BOOLEAN NOT NULL DEFAULT false,
    status                  VARCHAR(20) NOT NULL DEFAULT 'active',  -- active, inactive
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE payment_accounts IS 'Owner-configured MPESA payment accounts. Passenger never sees raw owner phone number.';

CREATE TABLE rides (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Participants
    passenger_id            UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    rider_id                UUID REFERENCES users(id) ON DELETE RESTRICT,  -- NULL until assigned

    -- Locations (raw coordinates always stored, place references optional)
    pickup_lat              DECIMAL(10, 7) NOT NULL,
    pickup_lng              DECIMAL(10, 7) NOT NULL,
    destination_lat         DECIMAL(10, 7) NOT NULL,
    destination_lng         DECIMAL(10, 7) NOT NULL,
    pickup_place_id         UUID REFERENCES places(id) ON DELETE RESTRICT,
    destination_place_id    UUID REFERENCES places(id) ON DELETE RESTRICT,

    -- Ride state (derived from ride_events via trigger — BR-022)
    status                  ride_status NOT NULL DEFAULT 'REQUESTED',
    cancelled_by            cancelled_by,
    cancel_reason           cancel_reason,
    booking_type            booking_type NOT NULL,

    -- Payment state (derived from payment_events via trigger — BR-022)
    payment_status          payment_status NOT NULL DEFAULT 'PENDING',
    refunded                BOOLEAN NOT NULL DEFAULT false,
    refunded_at             TIMESTAMPTZ,
    payment_account_id      UUID REFERENCES payment_accounts(id) ON DELETE RESTRICT,

    -- Payment method tracking
    preferred_payment_method VARCHAR(20),  -- CASH, MPESA
    actual_payment_method    VARCHAR(20),  -- CASH, MPESA
    payment_method_changed   BOOLEAN NOT NULL DEFAULT false,
    payment_change_reason    TEXT,

    -- Share Ride
    share_token             VARCHAR(64) UNIQUE,
    share_token_active      BOOLEAN NOT NULL DEFAULT false,
    share_token_expired_at  TIMESTAMPTZ,

    -- Fare
    fare_amount             DECIMAL(10, 2),

    -- Timestamps per state transition
    requested_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    owner_reviewed_at       TIMESTAMPTZ,
    fare_sent_at            TIMESTAMPTZ,
    fare_accepted_at        TIMESTAMPTZ,
    rider_assigned_at       TIMESTAMPTZ,
    rider_en_route_at       TIMESTAMPTZ,
    arrived_at              TIMESTAMPTZ,
    in_progress_at          TIMESTAMPTZ,
    completed_at            TIMESTAMPTZ,
    cancelled_at            TIMESTAMPTZ,

    -- Optimistic concurrency control (BR-041)
    version                 INTEGER NOT NULL DEFAULT 1,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- ================================================================
    -- CHECK constraints
    -- ================================================================

    -- BR-010: refund only valid on successful payment
    CONSTRAINT chk_refund_requires_success
        CHECK (refunded = false OR payment_status = 'SUCCESS'),

    -- Cancellation metadata only present when cancelled
    CONSTRAINT chk_cancel_metadata
        CHECK (
            (status = 'CANCELLED' AND cancelled_by IS NOT NULL AND cancel_reason IS NOT NULL)
            OR (status != 'CANCELLED' AND cancelled_by IS NULL AND cancel_reason IS NULL)
        ),

    -- Coordinate sanity (NFR §1)
    CONSTRAINT chk_pickup_lat CHECK (pickup_lat BETWEEN -90 AND 90),
    CONSTRAINT chk_pickup_lng CHECK (pickup_lng BETWEEN -180 AND 180),
    CONSTRAINT chk_destination_lat CHECK (destination_lat BETWEEN -90 AND 90),
    CONSTRAINT chk_destination_lng CHECK (destination_lng BETWEEN -180 AND 180),

    -- No null-island
    CONSTRAINT chk_pickup_not_null_island CHECK (NOT (pickup_lat = 0 AND pickup_lng = 0)),
    CONSTRAINT chk_destination_not_null_island CHECK (NOT (destination_lat = 0 AND destination_lng = 0))
);

COMMENT ON TABLE rides IS 'Core transaction table. Current state derived from events via triggers (BR-022). Terminal: COMPLETED, CANCELLED only (BR-009).';
COMMENT ON COLUMN rides.status IS 'Current ride status. NEVER written directly — only by ride_events trigger (BR-022).';
COMMENT ON COLUMN rides.payment_status IS 'Current payment status. NEVER written directly — only by payment_events trigger (BR-022).';
COMMENT ON COLUMN rides.version IS 'Optimistic concurrency — incremented on every state change (BR-041).';
COMMENT ON COLUMN rides.share_token IS 'Long random string, never the ride_id. Auto-created at RIDER_ASSIGNED (BR-013).';
