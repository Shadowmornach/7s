-- ============================================================
-- 7s TOMS — Migration 008: Supporting Tables
-- Cash handovers, ratings, configuration.
-- ============================================================

-- Cash Handovers — append-only financial record (BR-011)
CREATE TABLE cash_handovers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id        UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    expected_cash   DECIMAL(10, 2) NOT NULL,
    actual_cash     DECIMAL(10, 2) NOT NULL,
    difference      DECIMAL(10, 2) NOT NULL GENERATED ALWAYS AS (actual_cash - expected_cash) STORED,
    received_by     UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,  -- the owner
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE cash_handovers IS 'Append-only. Never edited after creation — corrections are new entries (BR-011).';
COMMENT ON COLUMN cash_handovers.difference IS 'Computed: actual - expected. Positive = overage, negative = shortfall.';

-- Ratings — one per completed ride, immutable (BR-033)
CREATE TABLE ratings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id     UUID NOT NULL REFERENCES rides(id) ON DELETE RESTRICT,
    rated_by    UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    rated_user  UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    score       INTEGER NOT NULL,
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- One rating per ride per rater
    CONSTRAINT uq_one_rating_per_ride UNIQUE (ride_id, rated_by),
    -- Score must be 1-5
    CONSTRAINT chk_score_range CHECK (score BETWEEN 1 AND 5),
    -- Cannot rate yourself
    CONSTRAINT chk_no_self_rating CHECK (rated_by != rated_user)
);

COMMENT ON TABLE ratings IS 'Immutable once submitted. One per completed ride within 24h window (BR-033).';

-- Configuration — runtime settings (Document 6)
CREATE TABLE configuration (
    key         VARCHAR(100) PRIMARY KEY,
    value       TEXT NOT NULL,
    description TEXT,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by  UUID REFERENCES users(id) ON DELETE RESTRICT
);

COMMENT ON TABLE configuration IS 'Owner-adjustable runtime settings. Backend reads config.<key>, never hardcoded values (Doc 6).';
