-- SQL Migration: 021_refresh_token_invalidation.sql
-- Create tracking table for invalidated refresh tokens

CREATE TABLE IF NOT EXISTS invalidated_refresh_tokens (
    token_hash VARCHAR(64) PRIMARY KEY,
    invalidated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS and deny all direct public access
ALTER TABLE invalidated_refresh_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System only access to invalidated_refresh_tokens" 
    ON invalidated_refresh_tokens
    FOR ALL
    TO authenticated
    USING (false)
    WITH CHECK (false);
