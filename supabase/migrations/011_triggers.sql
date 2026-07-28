-- ============================================================
-- 7s TOMS — Migration 011: Triggers
-- State derived from events. BR-022, BR-029, BR-041.
-- Current state columns are NEVER written directly by app code.
-- ============================================================

-- ============================================================
-- RIDE EVENTS TRIGGER
-- On ride_events INSERT → validate transition → update rides.status
-- ============================================================

CREATE OR REPLACE FUNCTION trg_ride_events_update_status()
RETURNS TRIGGER AS $$
DECLARE
    current_ride_status ride_status;
    new_status ride_status;
    current_version INTEGER;
BEGIN
    -- Acquire row-level lock on the ride (BR-041: concurrency control)
    SELECT status, version INTO current_ride_status, current_version
    FROM rides
    WHERE id = NEW.ride_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ride % not found', NEW.ride_id;
    END IF;

    -- Terminal states are final — no further events allowed except OWNER_NOTE
    IF current_ride_status IN ('COMPLETED', 'CANCELLED')
       AND NEW.ride_event_type NOT IN (
           'OWNER_NOTE',
           'SOS_TRIGGERED',
           'SOS_RESOLVED'
       ) THEN
        RAISE EXCEPTION 'Ride % is in terminal state %. No further state transitions permitted (BR-029).',
            NEW.ride_id, current_ride_status;
    END IF;

    -- Map event type to new ride status (only status-changing events)
    new_status := CASE NEW.ride_event_type
        WHEN 'RIDE_REQUESTED'   THEN 'REQUESTED'::ride_status
        WHEN 'OWNER_REVIEWED'   THEN 'OWNER_REVIEWING'::ride_status
        WHEN 'FARE_SENT'        THEN 'FARE_SENT'::ride_status
        WHEN 'FARE_ACCEPTED'    THEN 'FARE_ACCEPTED'::ride_status
        WHEN 'RIDER_ASSIGNED'   THEN 'RIDER_ASSIGNED'::ride_status
        WHEN 'RIDER_ACCEPTED'   THEN 'RIDER_EN_ROUTE'::ride_status
        WHEN 'ARRIVED'          THEN 'ARRIVED'::ride_status
        WHEN 'RIDE_STARTED'     THEN 'IN_PROGRESS'::ride_status
        WHEN 'RIDE_COMPLETED'   THEN 'COMPLETED'::ride_status
        WHEN 'RIDE_CANCELLED'   THEN 'CANCELLED'::ride_status
        ELSE NULL  -- Non-status-changing events (OWNER_NOTE, BREAKDOWN, etc.)
    END;

    -- If this event doesn't change status, allow it without validation
    IF new_status IS NULL THEN
        RETURN NEW;
    END IF;

    -- Validate transition against BR-029 state graph
    IF NOT (
        -- Initial event
        (current_ride_status = 'REQUESTED' AND new_status = 'REQUESTED')
        -- REQUESTED transitions
        OR (current_ride_status = 'REQUESTED' AND new_status IN ('OWNER_REVIEWING', 'RIDER_ASSIGNED', 'CANCELLED'))
        -- OWNER_REVIEWING transitions
        OR (current_ride_status = 'OWNER_REVIEWING' AND new_status IN ('FARE_SENT', 'CANCELLED'))
        -- FARE_SENT transitions
        OR (current_ride_status = 'FARE_SENT' AND new_status IN ('FARE_ACCEPTED', 'CANCELLED'))
        -- FARE_ACCEPTED transitions
        OR (current_ride_status = 'FARE_ACCEPTED' AND new_status IN ('RIDER_ASSIGNED', 'CANCELLED'))
        -- RIDER_ASSIGNED transitions
        OR (current_ride_status = 'RIDER_ASSIGNED' AND new_status IN ('RIDER_EN_ROUTE', 'CANCELLED'))
        -- RIDER_EN_ROUTE transitions
        OR (current_ride_status = 'RIDER_EN_ROUTE' AND new_status IN ('ARRIVED', 'CANCELLED'))
        -- ARRIVED transitions
        OR (current_ride_status = 'ARRIVED' AND new_status IN ('IN_PROGRESS', 'CANCELLED'))
        -- IN_PROGRESS transitions
        OR (current_ride_status = 'IN_PROGRESS' AND new_status IN ('COMPLETED', 'CANCELLED'))
    ) THEN
        RAISE EXCEPTION 'Invalid ride state transition: % → % (BR-029). Ride: %',
            current_ride_status, new_status, NEW.ride_id;
    END IF;

    -- Update ride current state + appropriate timestamp + increment version
    UPDATE rides
    SET status = new_status,
        version = current_version + 1,
        updated_at = now(),
        -- Set the appropriate timestamp for the new state
        owner_reviewed_at   = CASE WHEN new_status = 'OWNER_REVIEWING' THEN now() ELSE owner_reviewed_at END,
        fare_sent_at        = CASE WHEN new_status = 'FARE_SENT' THEN now() ELSE fare_sent_at END,
        fare_accepted_at    = CASE WHEN new_status = 'FARE_ACCEPTED' THEN now() ELSE fare_accepted_at END,
        rider_assigned_at   = CASE WHEN new_status = 'RIDER_ASSIGNED' THEN now() ELSE rider_assigned_at END,
        rider_en_route_at   = CASE WHEN new_status = 'RIDER_EN_ROUTE' THEN now() ELSE rider_en_route_at END,
        arrived_at          = CASE WHEN new_status = 'ARRIVED' THEN now() ELSE arrived_at END,
        in_progress_at      = CASE WHEN new_status = 'IN_PROGRESS' THEN now() ELSE in_progress_at END,
        completed_at        = CASE WHEN new_status = 'COMPLETED' THEN now() ELSE completed_at END,
        cancelled_at        = CASE WHEN new_status = 'CANCELLED' THEN now() ELSE cancelled_at END,
        -- Extract cancellation metadata from event metadata JSON
        cancelled_by        = CASE WHEN new_status = 'CANCELLED' THEN (NEW.metadata->>'cancelled_by')::cancelled_by ELSE cancelled_by END,
        cancel_reason       = CASE WHEN new_status = 'CANCELLED' THEN (NEW.metadata->>'cancel_reason')::cancel_reason ELSE cancel_reason END,
        -- Extract rider assignment
        rider_id            = CASE WHEN new_status = 'RIDER_ASSIGNED' THEN (NEW.metadata->>'rider_id')::UUID ELSE rider_id END,
        -- Auto-create share token at RIDER_ASSIGNED (BR-013)
        share_token         = CASE WHEN new_status = 'RIDER_ASSIGNED' AND share_token IS NULL
                                   THEN encode(gen_random_bytes(32), 'hex')
                                   ELSE share_token END,
        share_token_active  = CASE WHEN new_status = 'RIDER_ASSIGNED' THEN true
                                   WHEN new_status IN ('COMPLETED', 'CANCELLED') THEN false
                                   ELSE share_token_active END,
        share_token_expired_at = CASE WHEN new_status IN ('COMPLETED', 'CANCELLED') THEN now()
                                      ELSE share_token_expired_at END
    WHERE id = NEW.ride_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ride_events_after_insert
    BEFORE INSERT ON ride_events
    FOR EACH ROW
    EXECUTE FUNCTION trg_ride_events_update_status();


-- ============================================================
-- PAYMENT EVENTS TRIGGER
-- On payment_events INSERT → update rides.payment_status
-- ============================================================

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

CREATE TRIGGER trg_payment_events_after_insert
    BEFORE INSERT ON payment_events
    FOR EACH ROW
    EXECUTE FUNCTION trg_payment_events_update_status();
