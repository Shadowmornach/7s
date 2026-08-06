-- ============================================================
-- 7s TOMS — Migration 029: Profile Extensions & Theme Preference
-- Adds theme preference, emergency contacts, and profile picture storage policies.
-- ============================================================

-- 1. Add theme_preference column (SYSTEM, LIGHT, DARK)
ALTER TABLE users ADD COLUMN IF NOT EXISTS theme_preference VARCHAR(20) NOT NULL DEFAULT 'SYSTEM';

-- 2. Add emergency_contact column (JSONB: { "name": "...", "relationship": "...", "phone": "..." })
ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact JSONB;

COMMENT ON COLUMN users.theme_preference IS 'User UI theme preference: SYSTEM, LIGHT, DARK.';
COMMENT ON COLUMN users.emergency_contact IS 'Optional emergency contact details (name, relationship, phone).';
