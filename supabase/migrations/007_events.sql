-- ============================================================
-- 7s TOMS — Migration 007: Event Tables
-- Immutable, append-only audit trail. BR-022, BR-029.
-- ============================================================

-- Ride Events — lifecycle and operational events
CREATE TABLE ride_events (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id         UUID NOT NULL REFERENCES rides(id) ON DELETE RESTRICT,
    ride_event_type ride_event_type NOT NULL,
    actor_id        UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    lat             DECIMAL(10, 7),
    lng             DECIMAL(10, 7),
    metadata        JSONB DEFAULT '{}',  -- schema-flexible, event-specific attributes
    sequence_number BIGSERIAL NOT NULL,  -- monotonic ordering (BR-022)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ride_events IS 'Immutable, append-only. Every ride state change originates here. Triggers update rides.status (BR-022).';
COMMENT ON COLUMN ride_events.sequence_number IS 'Monotonic order — authoritative over created_at when timestamps tie (BR-022).';
COMMENT ON COLUMN ride_events.metadata IS 'Schema-flexible JSON. Fields promoted to columns only when indexing demands it (Doc 4 §3).';

-- Payment Events — payment lifecycle
CREATE TABLE payment_events (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id             UUID NOT NULL REFERENCES rides(id) ON DELETE RESTRICT,
    payment_event_type  payment_event_type NOT NULL,
    mpesa_receipt       VARCHAR(50),
    phone_number_used   VARCHAR(20),        -- override number if different from passenger's registered phone
    amount              DECIMAL(10, 2),
    raw_callback        JSONB,              -- full Daraja response — evidence of record (NFR §1)
    metadata            JSONB DEFAULT '{}',
    sequence_number     BIGSERIAL NOT NULL,  -- monotonic ordering (BR-022)
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE payment_events IS 'Immutable, append-only. Every payment status change originates here. Triggers update rides.payment_status (BR-022).';
COMMENT ON COLUMN payment_events.raw_callback IS 'Full Daraja callback stored as evidence for disputes (NFR §1).';
COMMENT ON COLUMN payment_events.phone_number_used IS 'Logged for one-off "pay with another number" cases. Never overwrites passenger account.';

-- SOS Alerts
CREATE TABLE sos_alerts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id         UUID NOT NULL REFERENCES rides(id) ON DELETE RESTRICT,
    triggered_by    UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    lat             DECIMAL(10, 7) NOT NULL,
    lng             DECIMAL(10, 7) NOT NULL,
    severity        sos_severity NOT NULL,
    emergency_type  VARCHAR(50) NOT NULL,  -- Robbery, Medical, Accident, Harassment, Vehicle Breakdown, Other
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE, RESOLVED
    resolution_notes TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at     TIMESTAMPTZ,
    resolved_by     UUID REFERENCES users(id) ON DELETE RESTRICT
);

COMMENT ON TABLE sos_alerts IS 'Immutable once created. Available from RIDER_ASSIGNED through payment resolution (BR-012).';
COMMENT ON COLUMN sos_alerts.severity IS 'Priority ordering: CRITICAL > HIGH > MEDIUM > LOW, then oldest-first (BR-012).';
