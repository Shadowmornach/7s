-- ============================================================
-- 7s TOMS — Migration 019: Payment Integrity
-- Enforces canonical payment identifiers and idempotency (BR-010).
-- ============================================================

-- 1. Canonical Identifier Idempotency
-- Ensure no two successful payments can ever claim the same M-PESA receipt.
-- We use a partial index because failed attempts or cash payments 
-- will not have an mpesa_receipt.
CREATE UNIQUE INDEX idx_payment_events_mpesa_receipt 
ON payment_events(mpesa_receipt) 
WHERE mpesa_receipt IS NOT NULL;

-- 2. Cash vs STK Race Condition Protection (BR-010)
-- Patch the existing trigger to reject any second SUCCESS payment 
-- before the event is even inserted, ensuring the ride stays locked to 
-- its first successful payment.

CREATE OR REPLACE FUNCTION trg_payment_events_update_status()
RETURNS TRIGGER AS $$
DECLARE
    current_pay_status payment_status;
    new_pay_status payment_status;
BEGIN
    -- Acquire row-level lock (BR-041)
    SELECT payment_status INTO current_pay_status
    FROM rides
    WHERE id = NEW.ride_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ride % not found', NEW.ride_id;
    END IF;

    -- BR-035: No PAYMENT_ATTEMPT after SUCCESS
    IF current_pay_status = 'SUCCESS' AND NEW.payment_event_type = 'PAYMENT_ATTEMPT' THEN
        RAISE EXCEPTION 'Cannot create PAYMENT_ATTEMPT for ride % — payment already succeeded (BR-035).', NEW.ride_id;
    END IF;

    -- BR-010: No multiple SUCCESS events per ride
    -- This enforces Policy D (Reject second payment). If Cash succeeds, a late STK callback is rejected.
    -- Because this is a BEFORE INSERT trigger, the exception completely aborts the insert
    -- preventing any side effects.
    IF current_pay_status = 'SUCCESS' AND NEW.payment_event_type = 'PAYMENT_SUCCESS' THEN
        RAISE EXCEPTION 'Cannot create PAYMENT_SUCCESS for ride % — payment already succeeded (BR-010).', NEW.ride_id;
    END IF;

    -- Map payment event type to new payment status
    new_pay_status := CASE NEW.payment_event_type
        WHEN 'PAYMENT_ATTEMPT'  THEN 'PENDING'::payment_status
        WHEN 'PAYMENT_SUCCESS'  THEN 'SUCCESS'::payment_status
        WHEN 'PAYMENT_FAILED'   THEN 'FAILED'::payment_status
        WHEN 'PAYMENT_DISPUTED' THEN 'DISPUTED'::payment_status
        WHEN 'REFUND_RECORDED'  THEN current_pay_status  -- Status stays SUCCESS; refunded flag handled separately
        ELSE current_pay_status
    END;

    -- Update ride payment state
    UPDATE rides
    SET payment_status = new_pay_status,
        actual_payment_method = COALESCE(NEW.metadata->>'payment_method', actual_payment_method),
        -- Handle refund flag for REFUND_RECORDED events
        refunded = CASE WHEN NEW.payment_event_type = 'REFUND_RECORDED' THEN true ELSE refunded END,
        refunded_at = CASE WHEN NEW.payment_event_type = 'REFUND_RECORDED' THEN now() ELSE refunded_at END,
        version = version + 1,
        updated_at = now()
    WHERE id = NEW.ride_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
