# 7s — Technical Architecture
## Master Document 4 of 5

This document defines *how* the business behavior in Documents 1–3 is implemented. It does not introduce new business logic — anything here that appears to add a rule is a bug in this document, per BR-025's precedence order (Documents 1–3 govern; this document serves them).

---

## 1. Stack

- **Frontend (mobile):** Flutter / Dart
- **Backend:** Python / FastAPI
- **Database:** PostgreSQL via Supabase (also provides Auth, Realtime for authenticated contexts, Storage)
- **Maps/Routing:** OpenStreetMap + OpenRouteService during development; evaluate Google Maps/Places/Routes before public launch based on real accuracy testing in Voi
- **Payments:** BambaStack API (M-Pesa STK Push gateway)
- **Push notifications:** Firebase Cloud Messaging
- **SMS:** deferred past V1 (see Document 1) — Africa's Talking is the planned provider if/when added

**Golden rule:** `Flutter → FastAPI → Supabase`. The Flutter client never talks to Supabase directly for anything involving business logic. FastAPI is the single gatekeeper — it validates permissions, enforces business rules, applies rate limits, and decides what data to return. Supabase RLS remains a second line of defense, not the primary one. This mirrors the pattern already proven on VigilantEdge.

**Exception:** the public Share Ride endpoint (`GET /share/{token}`) is the one deliberately unauthenticated path, and it still goes through FastAPI, not direct Supabase access (see Document 2, BR-013).

---

## 2. Data Model — Canonical Enums

These are the single authoritative definitions. No implementation, migration, or agent-written code should introduce a value not listed here — new values require updating this document first.

**`ride_status`**: `REQUESTED, OWNER_REVIEWING, FARE_SENT, FARE_ACCEPTED, RIDER_ASSIGNED, RIDER_EN_ROUTE, ARRIVED, IN_PROGRESS, COMPLETED, CANCELLED`
*(Only `COMPLETED`/`CANCELLED` are terminal — BR-009.)*

**`payment_status`**: `PENDING, SUCCESS, FAILED, DISPUTED`
*(No separate `REFUNDED` or `WRITTEN_OFF` status — refund is represented by the `refunded` boolean + `refunded_at` on top of `SUCCESS`, per the earlier decision to avoid an over-engineered payment state machine. A written-off dispute is simply a `DISPUTED` record the owner has resolved outside the system — logged via an `OWNER_NOTE` event, not a new payment_status value, keeping BR-010's CHECK constraint — `refunded=false OR payment_status='SUCCESS'` — meaningful and simple.)*

**`cancelled_by`**: `OWNER, PASSENGER, RIDER, SYSTEM`

**`cancel_reason`**: `OUTSIDE_SERVICE_AREA, NO_SHOW, OWNER_BUSY, OPERATING_HOURS, BREAKDOWN, UNSAFE_PICKUP, PAYMENT_TIMEOUT, PASSENGER_REQUEST, SYSTEM_TIMEOUT, FARE_DECLINED, REQUEST_TIMEOUT`

**`ride_event_type`** (`ride_events`): `RIDE_REQUESTED, OWNER_REVIEWED, FARE_SENT, FARE_ACCEPTED, RIDER_ASSIGNED, RIDER_ACCEPTED, RIDER_REJECTED, RIDE_STARTED, ARRIVED, NO_SHOW, ROUTE_DEVIATION, RIDE_COMPLETED, RIDE_CANCELLED, BREAKDOWN, ACCIDENT, SOS_TRIGGERED, SOS_RESOLVED, SHARE_RIDE_CREATED, OWNER_NOTE, TELEMETRY_UPDATE`

**`payment_event_type`** (`payment_events`): `PAYMENT_ATTEMPT, PAYMENT_SUCCESS, PAYMENT_FAILED, PAYMENT_DISPUTED, REFUND_RECORDED`

*These are separate enums — each table enforces its own set of valid values at the database level, preventing nonsense like a `PAYMENT_SUCCESS` row in `ride_events` or an `ARRIVED` row in `payment_events`.*

**`sos_severity`**: `CRITICAL, HIGH, MEDIUM, LOW`

**`booking_type`**: `INSTANT, MANUAL, RESTRICTED`

**`place_type`**: `SYSTEM, OWNER, USER`

**`place_origin`**: `MANUAL, GOOGLE, OSM, GPS`

**`role`**: `OWNER, RIDER, PASSENGER`

---

## 3. Schema Summary

*(Full DDL/migrations are implementation work, not this document — this is the conceptual shape.)*

```
users (id, phone_number, role, full_name, photo_url, created_at, is_active)
riders (id -> users.id, motorcycle_plate, motorcycle_model, license_number, id_verified, status, current_lat/lng, last_location_at, strike_count)
passengers (id -> users.id, strike_count)

places (id, name, latitude, longitude, place_type, origin, created_by, usage_count, active)
fare_templates (id, from_place_id, to_place_id, fare, estimated_distance, estimated_time, active, last_updated, notes)

rides (id, passenger_id, rider_id, pickup_lat/lng, destination_lat/lng, pickup_place_id, destination_place_id,
       status, cancelled_by, cancel_reason, booking_type,
       payment_status, refunded, refunded_at, payment_account_id,
       preferred_payment_method, actual_payment_method, payment_method_changed, payment_change_reason,
       share_token, share_token_active, share_token_expired_at,
       fare_amount, requested_at, ... timestamps per state)

ride_events (id, ride_id, ride_event_type, actor_id, lat/lng, metadata, sequence_number, created_at)
payment_events (id, ride_id, payment_event_type, status, mpesa_receipt, raw_callback, sequence_number, created_at)
sos_alerts (id, ride_id, triggered_by, lat/lng, severity, emergency_type, status, created_at, resolved_at)
cash_handovers (id, rider_id, expected_cash, actual_cash, difference, received_by, created_at)
ratings (id, ride_id, rated_by, rated_user, score, comment, created_at)
payment_accounts (id, provider, display_name, till_paybill_or_number, is_default, status)
configuration (key, value, updated_at, updated_by)  -- or a few focused tables; implementation choice
```

**Concurrency control (implements BR-041):** All ride state transitions execute inside a database transaction. Before appending a new `ride_event`, the backend re-reads the ride's current state and acquires the necessary row-level lock (or equivalent, e.g. optimistic version check) so that competing requests cannot both produce valid-looking but conflicting transitions. If validation fails after the lock is acquired — because another request already changed the ride's state first — the transaction rolls back completely and the losing request is rejected or retried against the now-current state, per BR-041.

**Triggers (per BR-022/BR-029):**
- `payment_events` insert → trigger updates `rides.payment_status`
- `ride_events` insert (of a valid transition) → trigger updates `rides.status`
- Both current-state columns are *never* written directly by application code — only by these triggers.

**Schema flexibility note:** `ride_events.metadata` (JSON) is append-only and intentionally schema-flexible — event-specific attributes belong there by default. A field only gets promoted to a first-class column when it needs reporting/indexing performance that JSON querying can't reasonably provide — this prevents the common drift where every new event type gets its own nullable column instead of using the field that already exists for this purpose.

**Constraints:**
- `CHECK (refunded = false OR payment_status = 'SUCCESS')` on `rides` (BR-010)
- FK enforcement everywhere; soft-deleted target rows remain valid references (BR-040)
- Uniqueness on `users.phone_number`

---

## 4. Project Structure

```
/mobile    ← Flutter app (Dart)
/backend   ← FastAPI (Python)
/docs      ← the five master documents (this repo's source of truth)
```

**Backend layering (FastAPI):**
```
backend/
  app/
    api/              # route handlers only — thin, no business logic
    services/         # booking engine, fare engine, payment engine, strike engine — business logic lives here
    models/            # Pydantic schemas (request/response) + DB models
    db/                # Supabase client, migrations
    integrations/       # BambaStack, OSM/Google, FCM — external API wrappers
    core/                # config, auth/JWT validation, rate limiting
  tests/
```
Route handlers stay thin and delegate to `services/` — this keeps business logic testable independent of HTTP, and matches BR-029's requirement that the server validates every transition centrally rather than scattered across endpoints.

**Flutter structure:** feature-first (not layer-first) — one folder per user-facing feature (booking, tracking, payment, operations_center, share_ride), each with its own widgets/state/api-client subfolders. Shared code (auth, theming, common widgets) in `/core`.

---

## 5. API Conventions

- REST over HTTPS, JSON bodies.
- Every authenticated endpoint requires a valid JWT; role-based access checked server-side (BR-002).
- Errors return a consistent shape: `{ "error_code": "...", "message": "..." }` — `error_code` is a stable machine-readable enum, `message` is human-readable, not the other way around.
- State-changing endpoints (assign rider, confirm cash, etc.) are idempotent where retried by mobile clients — the endpoint accepts a client-generated idempotency key or is naturally idempotent given the ride's current state (ties to BR-029's "server validates before appending an event" — a retried valid-already-applied request is a no-op, not a duplicate operation).
- Every successful state-changing request returns the newly derived current ride state (e.g. `ride_status`, `payment_status`, `version`), not merely `"success": true` — the client always knows the authoritative post-mutation state without a follow-up GET, which makes mobile synchronization dramatically easier and eliminates a class of race conditions where the client acts on stale state.
- Token Refresh: `POST /auth/refresh` supports JWT rotation (inbound `{ "refresh_token": str }`). Upon successful verification, the old refresh token signature is recorded in `invalidated_refresh_tokens` to prevent reuse.
- Inbound Telemetry: `POST /rides/{ride_id}/location` (authenticated as RIDER) accepts `{ "latitude": float, "longitude": float }` and appends a `TELEMETRY_UPDATE` event, triggering an asynchronous update to the rider's coordinate columns (`current_lat`/`current_lng`) in the database.
- Active SOS Details: `RideResponse` returns safety status fields: `active_sos_id` (UUID or null), `active_sos_severity` (Enum or null), and `active_sos_status` (Enum or null), enabling the client to display emergency banner UI states without auxiliary dashboard polling.
- Cash Handovers: `POST /operations/cash-handovers` (authenticated as OWNER) records an append-only cash handover record from a rider to an owner (BR-011).
- Fare Template Deactivation: `DELETE /api/v1/fare-templates/{template_id}` (authenticated as OWNER) deactivates (soft-deletes) a fare template (BR-040).
- Ride Rating: `POST /api/v1/rides/{ride_id}/rate` (authenticated) submits a rating for a completed ride within 24 hours of completion (BR-033).
- Public endpoints (only `GET /share/{token}`) are explicitly listed and reviewed for minimal data exposure — see Document 2, BR-013.

---

## 6. Notification Service

Implements Document 1/BR-015's rule: notifications are asynchronous side effects, never gate business transactions.

```
ride_events / payment_events / sos_alerts
        │
        ▼
Notification Dispatcher (reads event_type, looks up recipients + template)
        │
        ▼
FCM (V1) — SMS/WhatsApp/Email are pluggable additions later, same dispatcher
```
V1 recipient map (from Document 1): Ride Requested→Owner, Fare Ready→Passenger, Rider Assigned→Rider+Passenger, Ride Cancelled→affected users, Payment Success→Passenger, SOS→Owner.

Device/token lifecycle (registration, refresh, expiry) lives here, not in Document 2, per BR-031's scoping.

---

## 7. Build Order (unchanged from earlier decision)

1. **Ride Engine** — state machine, no maps/auth/payments, seeded test users, minimal role-switcher debug UI
2. **Maps** — current location, Places, service radius, routing
3. **Authentication** — real login for all three roles
4. **Live Updates** — Supabase Realtime for authenticated ride tracking
5. **Payments** — BambaStack integration, cash confirmation
6. **Reports & Operations** — revenue, history, rider/passenger/place management

---

## 8. Testing Strategy

- Business Rules (Document 2) are directly testable — each BR-xxx should map to at least one automated test case (this is what "implementation-ready" specifications are for).
- Priority order matches build order: ride state machine transition tests first (BR-009, BR-029, BR-041 concurrency), payment invariant tests second (BR-010 CHECK constraint, BR-035 sequencing), then integration tests for BambaStack/routing/notifications last, since those depend on external services and are naturally slower/flakier.
- Concurrency tests (BR-041 scenarios: double assignment, cancel-vs-start race) deserve explicit test cases, not just unit coverage, since races are exactly the kind of bug that passes casual manual testing.

---

## 9. Deployment (V1 scope)

- Single FastAPI instance (no horizontal scaling needed at this volume — per the Non-Functional Requirements doc)
- Supabase managed Postgres (no self-hosted DB, no read replicas)
- Flutter builds distributed via normal app store / APK distribution — no special CI/CD complexity required for V1 volume
- Background/scheduled jobs (timeout checks, stale-request expiry) via Supabase Edge Function cron or a lightweight in-process scheduler in FastAPI — not a full job queue system

---

*This document must remain consistent with Documents 1–3. Where a technical decision here would require violating a Business Rule, the Business Rule wins (BR-025) and this document is corrected, not the rule.*
