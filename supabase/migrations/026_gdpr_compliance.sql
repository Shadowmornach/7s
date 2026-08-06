-- ============================================================
-- 7s TOMS — Migration 026: GDPR & EU Privacy Audit Trail & Soft Delete
-- Non-destructive additive migration.
-- ============================================================

-- 1. Add consent audit columns with FALSE defaults & explicit timestamps
ALTER TABLE users ADD COLUMN IF NOT EXISTS consent_given_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS consent_version VARCHAR(20) DEFAULT 'v1.0';
ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_policy_accepted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS terms_accepted BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Add Soft Delete & 30-Day Recovery Window columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS deletion_pending_until TIMESTAMPTZ;

-- 3. Create deleted_users audit log table for compliance records
CREATE TABLE IF NOT EXISTS deleted_users_audit (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id                 UUID NOT NULL,
    email_hash              VARCHAR(64) NOT NULL,
    requested_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    scheduled_purge_at      TIMESTAMPTZ NOT NULL,
    status                  VARCHAR(20) NOT NULL DEFAULT 'PENDING_30_DAY_PURGE'
);

COMMENT ON COLUMN users.privacy_policy_accepted IS 'Must be explicitly set to true by user during sign up (BR-GDPR-001).';
COMMENT ON COLUMN users.terms_accepted IS 'Must be explicitly set to true by user during sign up (BR-GDPR-002).';
COMMENT ON COLUMN users.deletion_pending_until IS 'Soft delete 30-day recovery window before permanent purge (Art 17).';
