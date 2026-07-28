-- ============================================================
-- 7s TOMS — Migration 004: Places
-- Single table for all place types. BR-014.
-- ============================================================

CREATE TABLE places (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255) NOT NULL,
    latitude    DECIMAL(10, 7) NOT NULL,
    longitude   DECIMAL(10, 7) NOT NULL,
    place_type  place_type NOT NULL,
    origin      place_origin NOT NULL DEFAULT 'MANUAL',
    created_by  UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    usage_count INTEGER NOT NULL DEFAULT 0,
    active      BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Sanity: valid coordinate ranges (NFR §1 — GPS sanity check)
    CONSTRAINT chk_latitude_range CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_longitude_range CHECK (longitude BETWEEN -180 AND 180),
    -- Prevent null-island (0,0) — common bug from denied GPS permission
    CONSTRAINT chk_not_null_island CHECK (NOT (latitude = 0 AND longitude = 0))
);

COMMENT ON TABLE places IS 'All places: SYSTEM (app defaults), OWNER (owner-added), USER (personal saved). BR-014.';
COMMENT ON COLUMN places.place_type IS 'Drives RLS visibility. USER places private to creator (BR-014).';
COMMENT ON COLUMN places.origin IS 'Informational provenance only. Never drives access control (BR-014).';
COMMENT ON COLUMN places.usage_count IS 'Tracks frequency for Suggested Fare Template prompts.';
