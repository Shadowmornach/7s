-- ============================================================
-- 7s TOMS — Migration 017: Fix Fare Templates RLS
-- BR-040 Correction
-- ============================================================

-- Drop the overly restrictive read policy
DROP POLICY IF EXISTS fare_templates_select ON fare_templates;

-- Recreate it without the `active = true` filter.
-- Filtering of active vs inactive templates belongs in the
-- application logic (operational query) to allow historical
-- reporting/audit queries to read soft-deleted templates.
CREATE POLICY fare_templates_select ON fare_templates
    FOR SELECT USING (true);
