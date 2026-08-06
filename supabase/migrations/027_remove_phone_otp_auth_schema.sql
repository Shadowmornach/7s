-- ============================================================
-- 7s TOMS — Migration 027: Remove Phone OTP & Cryptographic Email Reset Schema
-- Cleans legacy phone OTP auth schema constraints and adds email OTP reset table storing SHA-256 hashes only.
-- ============================================================

-- 1. Ensure users.phone_number is strictly optional (payment MSISDN only)
ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;

-- 2. Drop any legacy phone OTP comments or constraints
COMMENT ON COLUMN users.phone_number IS 'Optional M-Pesa payment MSISDN (Format: 0712xxxxxx / 2547...). Not used for authentication.';

-- 3. Email password resets table storing SHA-256 hashed OTPs
CREATE TABLE IF NOT EXISTS email_password_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL,
    otp_code_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    is_used BOOLEAN NOT NULL DEFAULT false,
    attempts INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_email_password_resets_lookup ON email_password_resets (email, expires_at, is_used);

COMMENT ON TABLE email_password_resets IS 'Stores SHA-256 hashed 6-digit email OTPs for self-service password reset flows.';
