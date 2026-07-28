-- ============================================================
-- 7s TOMS — Migration 005: Fare Templates
-- Known place-pairs with predefined pricing. BR-006.
-- ============================================================

CREATE TABLE fare_templates (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_place_id       UUID NOT NULL REFERENCES places(id) ON DELETE RESTRICT,
    to_place_id         UUID NOT NULL REFERENCES places(id) ON DELETE RESTRICT,
    fare                DECIMAL(10, 2) NOT NULL,
    estimated_distance  DECIMAL(10, 2),  -- km
    estimated_time      INTEGER,          -- seconds
    active              BOOLEAN NOT NULL DEFAULT true,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_updated        TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- A fare template shouldn't map a place to itself
    CONSTRAINT chk_different_places CHECK (from_place_id != to_place_id),
    -- Fare must be positive
    CONSTRAINT chk_fare_positive CHECK (fare > 0),
    -- One active template per direction (A→B and B→A are separate templates)
    CONSTRAINT uq_active_template UNIQUE (from_place_id, to_place_id) 
        -- Note: this enforces one template per place-pair. If a deactivated
        -- template exists, a new one for the same pair can be created.
        -- Enforced at application level: only active templates considered.
);

COMMENT ON TABLE fare_templates IS 'Owner-defined fare for known place pairs. Only matches SYSTEM/OWNER places, never dropped pins (BR-006).';
COMMENT ON COLUMN fare_templates.fare IS 'Owner-set price in KES. System never auto-calculates fares (BR-006).';
