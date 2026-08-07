-- ============================================================
-- 7s TOMS — Migration 030: Standardize on Supabase Auth & Remove Google Auth
-- Cleanly deprecate legacy google_id column and setup automatic user sync trigger.
-- ============================================================

-- 1. Drop legacy index on google_id
DROP INDEX IF EXISTS idx_users_google_id;

-- 2. Drop google_id column from users table
ALTER TABLE users DROP COLUMN IF EXISTS google_id;

-- 3. Create auth sync function for Supabase Auth auth.users -> public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, role, full_name, photo_url, email_verified, is_active, is_profile_complete, service_zone)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE((NEW.raw_user_meta_data->>'role')::VARCHAR, 'PASSENGER'),
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url',
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
        true,
        false,
        'VOI'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        email_verified = EXCLUDED.email_verified,
        updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
