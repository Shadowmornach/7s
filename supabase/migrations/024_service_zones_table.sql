-- ============================================================
-- 7s TOMS — Migration 024: Normalized Service Zones Table & User Preference
-- Scalable multi-zone support (Voi Town initial record + future expansion).
-- ============================================================

CREATE TABLE IF NOT EXISTS service_zones (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code        VARCHAR(20) NOT NULL UNIQUE,
    name        VARCHAR(100) NOT NULL,
    county      VARCHAR(100) NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    center_lat  DECIMAL(10, 7) NOT NULL,
    center_lng  DECIMAL(10, 7) NOT NULL,
    radius_km   DECIMAL(6, 2) NOT NULL DEFAULT 15.00,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE service_zones IS 'Supported operational zones (Voi Town active initial, future Taveta/Wundanyi/Mombasa).';

-- Insert initial active zone: VOI
INSERT INTO service_zones (code, name, county, is_active, center_lat, center_lng, radius_km)
VALUES ('VOI', 'Voi Town', 'Taita-Taveta', true, -3.396667, 38.556111, 15.00)
ON CONFLICT (code) DO NOTHING;

-- Add foreign key default_service_zone_id on users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS default_service_zone_id UUID REFERENCES service_zones(id) ON DELETE SET NULL;
