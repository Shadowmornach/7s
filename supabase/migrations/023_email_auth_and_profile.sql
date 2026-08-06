-- ============================================================
-- 7s TOMS — Migration 023: Email Authentication & User Profile Extension
-- Non-destructive schema evolution for Email/Password auth and profile completion.
-- ============================================================

-- 1. Make phone_number optional for email-based registration
ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;

-- 2. Add email column with unique constraint
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255) UNIQUE;

-- 3. Add profile completion fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS nickname VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS service_zone VARCHAR(50) NOT NULL DEFAULT 'VOI';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_profile_complete BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_payment_method VARCHAR(50) NOT NULL DEFAULT 'Cash';

-- 4. Add index on email for fast lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email) WHERE email IS NOT NULL;

-- 5. RLS Policy: Allow users to update their own profile fields
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'users_update_own_profile'
    ) THEN
        CREATE POLICY users_update_own_profile ON users
            FOR UPDATE USING (auth.uid() = id)
            WITH CHECK (auth.uid() = id);
    END IF;
END $$;
