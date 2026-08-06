# 7s — Business Rules (BR)
## Master Document 2 of 5

Business Rules define invariants of the system. They describe conditions that must always hold true, regardless of implementation language, database technology, framework, or user interface. Where Document 1 (Business Workflow) describes movement, this document describes constraints.

Numbers marked **[DEFAULT — confirm]** are reasonable starting values, not values the owner has explicitly set. They belong in Configuration (owner-adjustable), not hardcoded, and should be revisited once real usage exists.

---

### BR-001 — Passenger Registration
- Self-service registration is supported via Google Sign-In (server-verified OAuth ID token) or Email and Password.
- Email address must be unique across accounts. Self-service signup is strictly restricted to the `PASSENGER` role (Rider and Owner accounts require administrative provisioning via `/auth/provision`).
- Phone number is **optional** at registration and profile completion. Cash-only users are never prompted for a phone number.
- Phone number is collected conditionally **only when a passenger selects M-Pesa** as their payment method for the first time, and is saved to their user profile for future M-Pesa payments (DL-026).

### BR-002 — Authentication
- Primary authentication methods: Google Sign-In (ID token server-validated via Google OAuth2) and Email/Password with JWT session tokens (access and refresh tokens).
- Authentication tokens are issued by the backend service; the API trusts only validated JWT tokens and server-verified OAuth identity assertions, never client-supplied role information.
- Role (`OWNER` / `RIDER` / `PASSENGER`) is a server-side claim embedded in the JWT token payload, never inferred client-side.
- No per-ride OTP is required (decided).


### BR-003 — Rider Verification & Online Status
- A rider may go online only if: account is active, `id_verified = true`, and rider is not suspended.
- Unverified riders cannot appear in any assignment path, automatic or manual.

### BR-004 — Suspension
- Owner may suspend a Passenger or Rider for: repeated no-shows, payment refusal, fake bookings, harassment, fraud, dangerous behaviour, SOS misuse.
- A suspended account cannot log new ride requests (passenger) or go online (rider).
- Suspension check runs first, before any other booking logic (see BR-005).

### BR-005 — Booking Classification
Runs in this exact order, every time, no exceptions:
1. Passenger suspended? → reject outright.
2. Strike count ≥ Restricted Booking threshold (**2 [DEFAULT — confirm]**)? → **Restricted Booking**, always to Owner Review, even if a Fare Template matches.
3. Pickup & destination both match an active Fare Template (both selected from Places, not a dropped pin)? → **Instant Booking**. Otherwise → **Manual Booking** (Owner Review).

### BR-006 — Fare Rules
- Only the owner sets manual fares; the system never automatically calculates or proposes a ride fare (distance/ETA calculation is separate — that's routing, not pricing).
- Fare Templates are only created/edited by the owner — the system may *suggest* one after a route repeats, never auto-create it.
- Fare Templates require `active = true` and both place IDs to be valid, non-deleted Places.

### BR-007 — Owner Review
- Manual and Restricted bookings enter `OWNER_REVIEWING` and must resolve within **3 minutes [DEFAULT — confirm]** or auto-cancel (`CANCELLED, cancelled_by=SYSTEM, reason=REQUEST_TIMEOUT`).
- Owner sees passenger rating and strike count before deciding.
- Fare response (`FARE_SENT` → passenger decision) must resolve within **5 minutes [DEFAULT — confirm]** or auto-cancel with the same reason.

### BR-008 — Rider Assignment
- If exactly one rider is online: auto-assign after owner approval.
- If 2+ riders online: owner manually selects (documented V1 boundary — not automated further in V1).
- Assigned rider must accept/reject within **60 seconds [DEFAULT — confirm]**; no response is treated as rejection, owner is notified, reassignment required.
- Owner may assign himself.

### BR-009 — Ride State Rules
- Ride status has exactly two terminal states: `COMPLETED`, `CANCELLED`. No other terminal status may exist.
- **Definition — Active Ride:** any ride whose status is not one of the two terminal states above. This is the canonical definition referenced by BR-026 and BR-027; it is defined once here rather than duplicated.
- `ARRIVED → IN_PROGRESS` occurs only when the rider explicitly taps "Start Ride" — never inferred from GPS proximity.
- Every ride status change is derived from a `ride_events` row via database trigger; direct writes to `rides.status` bypassing an event are prohibited.
- A ride reaching `COMPLETED` is independent of `payment_status` — a completed ride may have any payment status.
- No active status may persist indefinitely without a timeout-driven resolution (see BR-021).

### BR-010 — Payment Rules
- `payment_status` on `rides` reflects current truth only; `payment_events` is the immutable history.
- Payment status changes only via a new `payment_events` row plus its database trigger — never edited directly.
- `refunded = true` requires `payment_status = 'SUCCESS'`, enforced by a database CHECK constraint, not application code alone.
- No automated refund (no Daraja B2C in V1) — refunds are manual owner action + `REFUND_RECORDED` event + `refunded=true` flag.
- Only one `SUCCESS` payment event is permitted per ride — a ride cannot accumulate multiple successful payments; this is enforced alongside BR-035's prohibition on further `PAYMENT_ATTEMPT` events after success.
- Payment method locks once `payment_status = SUCCESS`; corrections after that point are new records, never edits.
- If no default active payment account is configured, MPESA is unavailable for new rides — only Cash is offered.
- MPESA STK timeout: **90 seconds [DEFAULT — confirm, matches Daraja's own window]** before querying STK status; treat as failure only if the query also returns nothing.
- Maximum MPESA retry attempts per ride: **3 [DEFAULT — confirm]** before forcing a cash fallback prompt.

### BR-011 — Cash Handling
- A ride cannot close on the cash path without an explicit "Cash Received" confirmation from the rider.
- Passenger refusal → `payment_status = DISPUTED`. The ride may already be `COMPLETED`; only the payment workflow remains unresolved (per BR-009, ride status and payment status are independent — resolution of the dispute itself is a Business Policy matter, not this document).
- Cash Handovers are their own append-only financial record (`cash_handovers`); never edited after creation — corrections are new adjustment entries.

### BR-012 — SOS Rules
- SOS is available from `RIDER_ASSIGNED` through payment resolution — not just `IN_PROGRESS`.
- Owner-triggered SOS (owner riding) logs the event only — no notification chain, since there is no one else to notify in V1.
- Multiple active alerts are ordered by severity first (`CRITICAL > HIGH > MEDIUM > LOW`), then oldest-first within the same severity.
- No SMS/call escalation in V1 — this is a stated, documented limitation, not a silent gap.

### BR-013 — Share Ride
- One `share_token` per ride (long random string, never the `ride_id`), auto-created at `RIDER_ASSIGNED`.
- Public endpoint returns only: rider name/photo/plate/rating, live position, ETA, coarse status. Never phone numbers, payment data, or ride history.
- Token invalidates on any terminal ride state, not only `COMPLETED`.
- Public share endpoint is rate-limited independently: **60 requests/minute per IP [DEFAULT — confirm]**.
- Client polls every **5–10 seconds [DEFAULT — confirm]**; Supabase Realtime is never exposed to this unauthenticated endpoint. This poll interval is independent of the rider's underlying GPS/location update frequency (BR-032, Configuration-driven) — the share page polls the backend on its own schedule regardless of how often the rider's device actually reports a new position; a poll may simply return the same last-known position if no fresher update has landed yet.

### BR-014 — Places
- Single `places` table; `place_type` (`SYSTEM`/`OWNER`/`USER`) drives RLS and visibility; `origin` (`MANUAL`/`GOOGLE`/`OSM`/`GPS`) is informational only and never drives access control.
- `USER`-type places are private — readable only by their creator, invisible to everyone else including the owner.
- `SYSTEM` and `OWNER` places are globally readable; only the owner can create/edit/deactivate them.

### BR-015 — Notifications
- Notifications are asynchronous side effects of events — they never gate, block, or roll back the underlying business transaction.
- Failure to deliver a notification must never cause a business operation (ride creation, payment recording, status change) to fail.
- V1 scope: push notifications only, per the Document 1 recipient table. SMS/WhatsApp/email are out of scope.

### BR-016 — Offline / Degraded-Network Behaviour
- Ride state, GPS trail, SOS events, and payment state are cached locally on network loss and sync automatically on reconnect.
- GPS permission denial never blocks booking — falls back to Places / Drop Pin.
- Last known location is retained and surfaced to the owner if a ride goes unexpectedly inactive (network loss or dead battery).

### BR-017 — Operating Hours
- Ride requests are accepted only during configured operating hours (BR-021 in the earlier draft numbering, retained here as its own rule).
- Outside operating hours: no request is created; passenger is told the business is closed and may call the owner directly for exceptions.

### BR-018 — Service Radius
- Service area is a center point + radius (not a polygon) for V1, owner-configurable.
- Pickup and destination must both fall inside the radius, checked server-side (not only in the Flutter map UI) — a modified client must not be able to bypass this.
- Outside-radius requests are rejected immediately with no request record created.

### BR-019 — Strike System
- Strike count is a per-account integer, incremented by defined events: payment refusal (after owner review), no-show, and other suspension-track behaviors.
- Restricted Booking threshold is owner-configurable in Settings (see BR-005), default **2 [DEFAULT — confirm]**.
- Strike count alone never auto-suspends — suspension is always an explicit owner action (BR-004).

### BR-020 — Cancellation Rules
- Every cancellation carries `cancelled_by` (`OWNER`/`PASSENGER`/`RIDER`/`SYSTEM`) and a `cancel_reason` from a fixed enum — never free text.
- Canonical `cancel_reason` values: `OUTSIDE_SERVICE_AREA, NO_SHOW, OWNER_BUSY, OPERATING_HOURS, BREAKDOWN, UNSAFE_PICKUP, PAYMENT_TIMEOUT, PASSENGER_REQUEST, SYSTEM_TIMEOUT, FARE_DECLINED, REQUEST_TIMEOUT` — this list is authoritative; any new reason must be added here, not invented ad hoc in code.
- Cancelling before rider assignment carries no strike; cancelling after assignment requires a reason and may carry a strike at owner discretion.

### BR-021 — Timeouts (consolidated)
All timeout and threshold values are owner-adjustable via Configuration at runtime. The table below shows starting defaults only — it is not a hardcoded specification, and the live values in Configuration are the source of truth at any given time.

| Timeout | Default |
|---|---|
| Email OTP expiry | 10 min |
| Email OTP cooldown | 60 sec |
| Owner review window | 3 min |
| Fare response window | 5 min |
| Rider accept/reject window | 60 sec |
| MPESA STK window | 90 sec |
| MPESA max retries | 3 |
| No-show wait time (rider at pickup) | 5 min |
| Stale queue-request expiry | 15 min |
| Duplicate submission window (BR-030) | 10 sec |
| Share endpoint rate limit | 60 req/min/IP |

All values above are **[DEFAULT — confirm]** and must live in Configuration, not hardcoded. Expired operations resolve automatically through system-generated events (e.g. `SYSTEM_TIMEOUT` → `ride_event` → trigger) — never by an implementation editing `rides.status` directly, which would violate BR-022.

### BR-022 — Audit Rules
- Events (`ride_events`, `payment_events`, `sos_alerts`) are immutable, append-only, and ordered by a monotonic event sequence number (not `created_at` alone — timestamps can tie, especially under concurrent writes; the sequence number is the authoritative order).
- Events cannot be edited or deleted.
- Current state (`rides.status`, `rides.payment_status`) is always derived from events via database trigger — never written directly by application code.
- Manual database edits to current-state or history tables are prohibited outside of documented migrations.

### BR-023 — Reporting Rules
- Revenue calculations use `payment_status = 'SUCCESS' AND refunded = false`.
- Cash vs. MPESA totals are computed from `payment_events`/`cash_handovers`, never estimated from ride counts alone.
- Reports never require scanning full event history at read time for values already mirrored onto `rides` (see BR-022) — use the current-state columns.

### BR-024 — Data Integrity Rules
- Soft deletes apply to mutable business records (users, places, rides, fare templates, payments) only; hard deletes reserved for short-lived caches/tokens only.
- Immutable event/audit tables (`ride_events`, `payment_events`, `sos_alerts`, `cash_handovers`) are never deleted — soft or hard. They are append-only logs by definition; a "deleted" event is a contradiction in terms. Corrections are new entries, never removals.
- Every `payment_events` row belongs to exactly one ride; every `ride_events` row belongs to exactly one ride.
- Foreign keys enforced at the database level, not just checked in application code.
- Invariants (e.g. the refund/payment-status CHECK constraint) are enforced by the database wherever possible, not solely by backend logic.
- Every ride must have exactly one current status at all times — no ride may be simultaneously represented by two conflicting state values.

### BR-025 — Rule Precedence
When two rules or decisions conflict, resolve in this order:
1. Data integrity rules take precedence over everything else.
2. Security rules take precedence over convenience.
3. Business Workflow (Document 1) defines sequence — the order things happen in.
4. Business Rules (this document) define validity — what's allowed to happen.
5. Business Policies (Document 3) define owner discretion — how ambiguous human situations are resolved.

### BR-026 — Rider Availability
A rider may have at most one Active Ride (per BR-009's definition) at any time. A rider already in an Active Ride cannot be assigned another; assignment is rejected server-side if this would be violated.

### BR-027 — Passenger Active Ride
A passenger may have only one Active Ride (per BR-009's definition) at a time. New ride requests are rejected while an existing ride is Active.

### BR-028 — Owner Self-Assignment While Riding
If the owner is currently assigned to an Active Ride (per BR-009), he cannot assign another ride to himself until that ride reaches a terminal state. He may still assign other riders, if any are online.

### BR-029 — Event Ordering / State Transition Graph
Events are appended in order per BR-022's monotonic event sequence number (not chronological timestamp — same authoritative ordering, referenced here rather than redefined). A ride's status transitions must follow the **allowed state graph** defined below — not a single linear sequence, because different booking types (BR-005) take different valid paths through the graph.

**Allowed transitions (the canonical state graph):**

```
REQUESTED
    ├──> OWNER_REVIEWING      (Manual / Restricted Booking)
    ├──> RIDER_ASSIGNED        (Instant Booking — fare template matched, no owner review needed)
    └──> CANCELLED

OWNER_REVIEWING
    ├──> FARE_SENT
    └──> CANCELLED

FARE_SENT
    ├──> FARE_ACCEPTED
    └──> CANCELLED

FARE_ACCEPTED
    ├──> RIDER_ASSIGNED
    └──> CANCELLED

RIDER_ASSIGNED
    ├──> RIDER_EN_ROUTE
    └──> CANCELLED

RIDER_EN_ROUTE
    ├──> ARRIVED
    └──> CANCELLED

ARRIVED
    ├──> IN_PROGRESS
    └──> CANCELLED

IN_PROGRESS
    ├──> COMPLETED
    └──> CANCELLED

COMPLETED    (terminal — no transitions out)
CANCELLED    (terminal — no transitions out)
```

A transition not listed above is invalid. Any attempted invalid transition (skipped states, transitions out of a terminal state, or a jump not in this graph) is explicitly rejected by the server with an error — never silently ignored or dropped. The server validates every requested transition against this graph before appending the corresponding `ride_event`.

### BR-030 — Duplicate Request Handling
Duplicate ride submissions are identified by the key **(passenger_id, pickup_place/coordinates, destination_place/coordinates)** — requests from the same passenger with the same pickup and destination within a short configurable window (**10 seconds [DEFAULT — confirm]**, see BR-021) are treated as one request, not separate bookings. A request differing in pickup or destination is never treated as a duplicate, regardless of timing — this protects against repeated taps from poor network conditions without collapsing genuinely different requests.

### BR-031 — Notification Recipients (Business Level)
One user may have multiple registered devices; notifications are delivered to all of that user's currently active/valid devices only — expired or invalidated device registrations do not receive notifications. Device/token lifecycle management (registration, expiry, replacement) is an implementation concern, defined in the Technical Architecture document, not here.

### BR-032 — Location Update Frequency
While a ride is active, rider location must update frequently enough to keep tracking meaningfully current for the owner, passenger, and Share Ride viewers — exact frequency (time-based, distance-based, or both) is a Configuration value, not fixed here. If the rider is offline or GPS is temporarily unavailable, updates are cached locally and synchronized in ascending event sequence once connectivity/GPS resumes (per BR-016) — so historical replay produces the same final state — never silently dropped, and never backfilled as if they happened in real time.

### BR-033 — Rating Rules
A passenger may submit exactly one rating per completed ride, within **24 hours [DEFAULT — confirm]** of completion. After 24 hours, the rating window expires permanently — no rating can be submitted for that ride afterward, and the ride is simply recorded as unrated. Ratings are immutable once submitted — no edits, same append-only philosophy as every other record in the system.

### BR-034 — Share Token Reactivation
An expired or invalidated share token can never be reactivated. A new ride requires a new token; there is no path to extend or revive an old one.

### BR-035 — Payment Attempt Sequencing
Once `payment_status = SUCCESS` for a ride, no further `PAYMENT_ATTEMPT` event may be created for that ride — prevents an accidental duplicate STK push after payment already succeeded. This does not restrict `PAYMENT_DISPUTED` or `REFUND_RECORDED` events, both of which are expected and valid *after* a successful payment (a dispute or a refund only make sense once money has actually moved).

### BR-036 — Location Source Priority
Pickup/destination location source follows one fixed priority, matching Document 1: **Current Location (if GPS permission granted) → Common/Saved Places → Search → Drop Pin.** GPS denial or unavailability skips directly to Places/Drop Pin — never a dead end.

### BR-037 — Owner Notes
Owner Notes attached to a ride or incident are append-only, same as every other event — no edits, no deletion. A correction is a new note, not a modification of the old one.

### BR-038 — Notification Delivery Idempotency
Notifications may be delivered more than once (push services can redeliver). Every notification carries a unique notification/event ID; clients use that ID to detect and safely ignore duplicates — the same notification arriving twice must never cause a duplicate user-visible action. This applies on both sides: if the backend retries a failed send (server-side retry), and if the push provider redelivers to the device (client-side duplicate), the same ID-based deduplication rule governs both cases.

### BR-039 — Configuration Change Scope
Configuration changes (service radius, timeouts, thresholds, etc.) affect only future ride requests, never rides already in progress at the time of the change, unless a rule explicitly states otherwise.

### BR-040 — Soft Delete Visibility
Soft-deleted records remain available for audit and reporting queries but are excluded from normal operational queries (e.g. a deactivated Place doesn't appear in pickup selection, but still appears in historical ride records that reference it). Foreign keys pointing to a soft-deleted record remain valid — a ride referencing a deactivated Place still displays that Place correctly in its details.

### BR-041 — Concurrency / State Transition Atomicity
All ride state transitions must execute inside a database transaction. Before appending a new `ride_event`, the backend must re-read the ride's current state and acquire a row-level lock (or equivalent, e.g. optimistic version check) so that competing requests cannot both produce valid-looking but conflicting transitions. If validation fails after the lock is acquired — because another request already changed the ride's state first — the transaction rolls back completely and the losing request is rejected with an error (or retried against the now-current state). Specifically:
- Two concurrent rider-assignment requests for the same ride must not both succeed — only one wins, the other is rejected.
- A cancel request and a start-ride request arriving simultaneously must not both succeed — the first to acquire the lock wins, the second validates against the resulting state and either proceeds (if still valid) or fails.
- This rule applies to all state-changing operations on a ride, not just status transitions — payment events, SOS events, and share token creation all acquire the ride-level lock before writing.
- This is a business invariant ("a ride has exactly one current state at all times" — BR-024), not merely an implementation preference.
