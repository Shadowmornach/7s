-- ============================================================
-- 7s TOMS — Migration 015: System User
-- Required for automated background tasks (Timeout Service)
-- to adhere to Event Sourcing integrity (BR-022) without RLS issues.
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = '00000000-0000-0000-0000-000000000000') THEN
        INSERT INTO users (id, phone_number, role, full_name)
        VALUES ('00000000-0000-0000-0000-000000000000', '+00000000000', 'OWNER', 'SYSTEM')
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
