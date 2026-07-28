-- ============================================================
-- 7s TOMS — Migration 002: Canonical Enums
-- Single authoritative definitions. Document 4 §2.
-- New values require updating docs/04_technical_architecture.md first.
-- ============================================================

CREATE TYPE ride_status AS ENUM (
    'REQUESTED',
    'OWNER_REVIEWING',
    'FARE_SENT',
    'FARE_ACCEPTED',
    'RIDER_ASSIGNED',
    'RIDER_EN_ROUTE',
    'ARRIVED',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED'
);

CREATE TYPE payment_status AS ENUM (
    'PENDING',
    'SUCCESS',
    'FAILED',
    'DISPUTED'
);

CREATE TYPE cancelled_by AS ENUM (
    'OWNER',
    'PASSENGER',
    'RIDER',
    'SYSTEM'
);

CREATE TYPE cancel_reason AS ENUM (
    'OUTSIDE_SERVICE_AREA',
    'NO_SHOW',
    'OWNER_BUSY',
    'OPERATING_HOURS',
    'BREAKDOWN',
    'UNSAFE_PICKUP',
    'PAYMENT_TIMEOUT',
    'PASSENGER_REQUEST',
    'SYSTEM_TIMEOUT',
    'FARE_DECLINED',
    'REQUEST_TIMEOUT'
);

CREATE TYPE ride_event_type AS ENUM (
    'RIDE_REQUESTED',
    'OWNER_REVIEWED',
    'FARE_SENT',
    'FARE_ACCEPTED',
    'RIDER_ASSIGNED',
    'RIDER_ACCEPTED',
    'RIDER_REJECTED',
    'RIDE_STARTED',
    'ARRIVED',
    'NO_SHOW',
    'ROUTE_DEVIATION',
    'RIDE_COMPLETED',
    'RIDE_CANCELLED',
    'BREAKDOWN',
    'ACCIDENT',
    'SOS_TRIGGERED',
    'SOS_RESOLVED',
    'SHARE_RIDE_CREATED',
    'OWNER_NOTE'
);

CREATE TYPE payment_event_type AS ENUM (
    'PAYMENT_ATTEMPT',
    'PAYMENT_SUCCESS',
    'PAYMENT_FAILED',
    'PAYMENT_DISPUTED',
    'REFUND_RECORDED'
);

CREATE TYPE sos_severity AS ENUM (
    'CRITICAL',
    'HIGH',
    'MEDIUM',
    'LOW'
);

CREATE TYPE booking_type AS ENUM (
    'INSTANT',
    'MANUAL',
    'RESTRICTED'
);

CREATE TYPE place_type AS ENUM (
    'SYSTEM',
    'OWNER',
    'USER'
);

CREATE TYPE place_origin AS ENUM (
    'MANUAL',
    'GOOGLE',
    'OSM',
    'GPS'
);

CREATE TYPE user_role AS ENUM (
    'OWNER',
    'RIDER',
    'PASSENGER'
);
