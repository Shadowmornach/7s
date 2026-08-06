-- ============================================================
-- 7s TOMS — Migration 025: Google OAuth Support & Account Linking
-- Non-destructive additive migration.
-- ============================================================

-- 1. Add google_id column with unique constraint
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) UNIQUE;

-- 2. Add email_verified flag
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;

-- 3. Ensure password_hash is nullable (for Google OAuth accounts)
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- 4. Create index on google_id
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id) WHERE google_id IS NOT NULL;
