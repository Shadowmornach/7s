-- ============================================================
-- 7s TOMS — Migration 028: Ride Messages Table for Realtime Transient Chat
-- Schema and RLS policies for active ride chat session between passenger and rider.
-- ============================================================

CREATE TABLE IF NOT EXISTS ride_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    sender_role user_role NOT NULL,
    message TEXT NOT NULL,
    is_quick_reply BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ride_messages_ride_id ON ride_messages(ride_id, created_at ASC);

COMMENT ON TABLE ride_messages IS 'Transient chat messages exchanged during an active ride.';
COMMENT ON COLUMN ride_messages.sender_role IS 'Role of message sender (PASSENGER, RIDER, OWNER).';
COMMENT ON COLUMN ride_messages.read_at IS 'Timestamp when recipient read the message.';

-- Enable RLS
ALTER TABLE ride_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Only passenger or assigned rider of the ride can read messages
CREATE POLICY ride_messages_select ON ride_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM rides r
            WHERE r.id = ride_messages.ride_id
              AND (r.passenger_id = auth.uid() OR r.rider_id = auth.uid())
        )
    );

-- RLS Policy: Only passenger or assigned rider of an active ride can insert messages
CREATE POLICY ride_messages_insert ON ride_messages
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM rides r
            WHERE r.id = ride_messages.ride_id
              AND (r.passenger_id = auth.uid() OR r.rider_id = auth.uid())
              AND r.status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS')
        )
    );
