-- ============================================================
-- 7s TOMS — Migration 031: Security Hardening for auth.users Trigger
-- Prevent client-controlled raw_user_meta_data->>'role' privilege escalation.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Security Invariant: Every self-serve signup via auth.users MUST strictly
    -- default to 'PASSENGER'. Never trust client-supplied raw_user_meta_data->>'role'.
    INSERT INTO public.users (
        id,
        email,
        role,
        full_name,
        photo_url,
        email_verified,
        is_active,
        is_profile_complete,
        service_zone
    )
    VALUES (
        NEW.id,
        NEW.email,
        'PASSENGER',
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
    -- Note: ON CONFLICT explicitly NEVER updates 'role', preserving any elevated role (RIDER/OWNER)
    -- that was authoritative in public.users.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-apply trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
