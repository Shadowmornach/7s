-- ============================================================
-- 7s TOMS — Migration 010: Views
-- Reusable across API, reports, admin screens.
-- ============================================================

-- Active rides (canonical definition — BR-009)
CREATE VIEW active_rides AS
SELECT r.*,
       u_passenger.full_name AS passenger_name,
       u_passenger.phone_number AS passenger_phone,
       u_rider.full_name AS rider_name,
       rd.motorcycle_plate
FROM rides r
JOIN users u_passenger ON r.passenger_id = u_passenger.id
LEFT JOIN users u_rider ON r.rider_id = u_rider.id
LEFT JOIN riders rd ON r.rider_id = rd.id
WHERE r.status NOT IN ('COMPLETED', 'CANCELLED');

COMMENT ON VIEW active_rides IS 'All non-terminal rides. Canonical active ride definition per BR-009.';

-- Ride summary (completed rides with payment and rider info)
CREATE VIEW ride_summary AS
SELECT r.id,
       r.status,
       r.booking_type,
       r.fare_amount,
       r.payment_status,
       r.refunded,
       r.actual_payment_method,
       r.requested_at,
       r.completed_at,
       r.cancelled_at,
       r.cancelled_by,
       r.cancel_reason,
       u_passenger.full_name AS passenger_name,
       u_passenger.phone_number AS passenger_phone,
       p_passenger.strike_count AS passenger_strikes,
       u_rider.full_name AS rider_name,
       rd.motorcycle_plate,
       pickup_place.name AS pickup_place_name,
       dest_place.name AS destination_place_name
FROM rides r
JOIN users u_passenger ON r.passenger_id = u_passenger.id
LEFT JOIN passengers p_passenger ON r.passenger_id = p_passenger.id
LEFT JOIN users u_rider ON r.rider_id = u_rider.id
LEFT JOIN riders rd ON r.rider_id = rd.id
LEFT JOIN places pickup_place ON r.pickup_place_id = pickup_place.id
LEFT JOIN places dest_place ON r.destination_place_id = dest_place.id;

COMMENT ON VIEW ride_summary IS 'Denormalized ride view for dashboard and history screens.';

-- Revenue summary (BR-023: only SUCCESS + not refunded)
CREATE VIEW revenue_summary AS
SELECT
    DATE(r.completed_at) AS ride_date,
    COUNT(*) AS ride_count,
    SUM(r.fare_amount) AS total_revenue
FROM rides r
WHERE r.payment_status = 'SUCCESS'
  AND r.refunded = false
  AND r.completed_at IS NOT NULL
GROUP BY DATE(r.completed_at)
ORDER BY ride_date DESC;

COMMENT ON VIEW revenue_summary IS 'Daily revenue by payment method. Uses payment_status=SUCCESS AND refunded=false only (BR-023).';

-- Rider performance
CREATE VIEW rider_performance AS
SELECT
    rd.id AS rider_id,
    u.full_name AS rider_name,
    rd.motorcycle_plate,
    rd.is_online,
    rd.strike_count,
    COUNT(r.id) FILTER (WHERE r.status = 'COMPLETED') AS completed_rides,
    COUNT(r.id) FILTER (WHERE r.status = 'CANCELLED' AND r.cancelled_by = 'RIDER') AS rider_cancelled,
    AVG(rat.score) AS avg_rating,
    COUNT(rat.id) AS rating_count
FROM riders rd
JOIN users u ON rd.id = u.id
LEFT JOIN rides r ON rd.id = r.rider_id
LEFT JOIN ratings rat ON rd.id = rat.rated_user
GROUP BY rd.id, u.full_name, rd.motorcycle_plate, rd.is_online, rd.strike_count;

COMMENT ON VIEW rider_performance IS 'Rider stats: completed rides, cancellations, average rating.';

-- Cash reconciliation
CREATE VIEW cash_reconciliation AS
SELECT
    ch.id AS handover_id,
    u_rider.full_name AS rider_name,
    ch.expected_cash,
    ch.actual_cash,
    ch.difference,
    u_received.full_name AS received_by_name,
    ch.created_at AS handover_time,
    CASE
        WHEN ch.difference = 0 THEN 'BALANCED'
        WHEN ch.difference > 0 THEN 'OVERAGE'
        ELSE 'SHORTFALL'
    END AS reconciliation_status
FROM cash_handovers ch
JOIN users u_rider ON ch.rider_id = u_rider.id
JOIN users u_received ON ch.received_by = u_received.id
ORDER BY ch.created_at DESC;

COMMENT ON VIEW cash_reconciliation IS 'Cash handover history with discrepancy classification (BP-011).';

-- Owner dashboard (today's snapshot)
CREATE VIEW owner_dashboard AS
SELECT
    (SELECT COUNT(*) FROM rides WHERE status NOT IN ('COMPLETED', 'CANCELLED')) AS active_rides,
    (SELECT COUNT(*) FROM rides WHERE status = 'COMPLETED' AND DATE(completed_at) = CURRENT_DATE) AS completed_today,
    (SELECT COUNT(*) FROM rides WHERE status = 'CANCELLED' AND DATE(cancelled_at) = CURRENT_DATE) AS cancelled_today,
    (SELECT COALESCE(SUM(fare_amount), 0) FROM rides WHERE payment_status = 'SUCCESS' AND refunded = false AND DATE(completed_at) = CURRENT_DATE) AS revenue_today,
    (SELECT COUNT(*) FROM riders WHERE is_online = true) AS riders_online,
    (SELECT COUNT(*) FROM sos_alerts WHERE status = 'ACTIVE') AS active_sos_alerts,
    (SELECT COUNT(*) FROM rides WHERE payment_status = 'DISPUTED') AS open_disputes;

COMMENT ON VIEW owner_dashboard IS 'Real-time snapshot for the owner Operations Center.';
