# 7s — Transport Operations Management System (TOMS)
## Consolidated Business Workflow (V1)
*Compiled from the full design conversation. This is Master Document 1 of 5 (Business Workflow, Business Rules, Business Policies, Technical Architecture, Non-Functional Requirements).*

---

## Core Philosophy

7s is not a ride-hailing platform competing with Uber/Bolt. It is a **digital dispatch and operations system for one motorcycle transport business**, currently operating in Voi / Taita Taveta County, Kenya. The owner is also a working rider. The system's job is to make the owner's existing daily operation more organized, not to replace how the business actually runs.

The MVP question for every feature: *does this help the owner complete today's rides more reliably?* If not, it's V2+.

---

## The Seven Core Domains

1. **Users** — Owner, Riders, Passengers (one `users` table + role-specific extension tables)
2. **Places** — the foundation everything else references
3. **Rides** — the transaction lifecycle (current state)
4. **Fare Templates** — known place-pairs with predefined pricing
5. **Payments** — `rides.payment_status` (current truth) + `payment_events` (append-only history)
6. **Events** — `ride_events`, the immutable timeline of everything that happens
7. **Configuration** — settings the owner controls without needing an app update

**Architectural rule:** every aggregate/root entity (rides) stores its *current* state directly on itself. Historical actions live in append-only event tables. **Current state is never edited directly — every change begins as an Event, and a database trigger updates the current state.** This is why `rides.status` coexists with `ride_events`, and `rides.payment_status` coexists with `payment_events`; it applies universally, not just to payments.

**Notifications** are treated as cross-cutting infrastructure, not a database domain or a V1 feature to design yet — SOS alerts, ride-assigned pushes, fare-ready pushes, payment confirmations, and Share Ride links all eventually flow through one notification layer (push now, possibly SMS/email/WhatsApp later). Acknowledged now so it isn't rediscovered as a new concept later; not designed until it's actually needed. **Notifications are asynchronous side effects of business events — they react to a state change after it happens, never decide or gate it. Failure to deliver a notification must never prevent or roll back the underlying business transaction** (push server down ≠ ride creation fails; Firebase outage ≠ payment fails to record).

---

## Roles

**Owner** — also rides. Reviews/accepts/rejects requests, sets manual fares, assigns riders (including himself), resolves disputes, handles SOS, manages riders/customers/places/fare templates, configures settings, views reports.

**Rider** — logs in, goes online/offline, accepts/rejects assigned rides, navigates, starts/completes rides, collects cash, does end-of-day cash handover, reports incidents, triggers SOS. Must be `id_verified` before going online.

**Passenger** — registers via phone + SMS OTP (login only, no per-ride OTP), requests rides, accepts/declines fares, tracks assigned rider, pays, rates, views history, saves personal places, triggers SOS.

---

## Configuration (owner-controlled, no app update needed)

- Business name, service radius (center point + radius, e.g. 20km from Voi CBD — circle, not polygon, for V1)
- Operating hours *(see BR-021 — must actually gate requests, not just be stored)*
- Restricted Booking strike threshold (default configurable, e.g. 2)
- Timeouts: owner-review window, fare-response window, rider accept/reject window, MPESA STK window, no-show wait time, stale-queue-request expiry
- Payment accounts (MPESA Till/Paybill/Personal — see Payments section)
- Passenger never sees the owner's raw phone number for payments — only business display name

---

## Places

Single `places` table for everything (not split into separate "Common Places" vs ad-hoc pins):

- `id, name, latitude, longitude, place_type, origin, created_by, usage_count, active`
- `place_type`: `SYSTEM` (app defaults, owner-editable, everyone reads) / `OWNER` (owner-added, everyone reads, only owner edits) / `USER` (passenger's own saved places — private, only creator can read or know it exists)
- `origin` (separate from `place_type`): `MANUAL / GOOGLE / OSM / GPS` — informational provenance only, does not drive RLS
- A random pin that isn't yet a saved Place keeps the ride's raw `pickup_lat/lng` — no Place record is forced

**Pickup/Destination selection UI order:** Current Location → Common (System/Owner) Places → Search → Drop Pin. Routing (distance/ETA) is required for V1; Place *search* (autocomplete/geocoding) can be deferred — those are two separate concerns.

---

## Fare Templates

- `fare_templates: id, from_place_id, to_place_id, fare, estimated_distance, estimated_time, active, last_updated, notes`
- Only matches when **both** pickup and destination were selected from Places (System or Owner type) — a dropped pin never matches a template
- Owner is shown a **"Suggested Fare Template"** prompt after an (unmatched) route repeats often — the app never auto-creates a template
- V2: zone-based pricing (Zone A → Zone B) as an evolution beyond exact place-pairs

---

## Booking Classification (runs on every ride request, in this order)

1. **Is passenger suspended?** → Yes: reject outright.
2. **Is passenger's strike count ≥ Restricted Booking threshold?** → Yes: **Restricted Booking** — always goes to Owner Review, even if a fare template matches.
3. **Does pickup→destination match an active Fare Template?** → Yes: **Instant Booking** (skip manual pricing). No: **Manual Booking** (goes to Owner Review Queue).

This order is deliberate: the risk check always runs before the pricing-shortcut check, so no risky passenger can bypass owner review via a fast path.

---

## Ride Lifecycle

**Active statuses (in order):**
`REQUESTED → OWNER_REVIEWING → FARE_SENT → FARE_ACCEPTED → RIDER_ASSIGNED → RIDER_EN_ROUTE → ARRIVED → IN_PROGRESS`

**Terminal statuses (only two):**
`COMPLETED` | `CANCELLED`

Everything that used to look like a separate terminal status (`DECLINED`, `REJECTED`, `EXPIRED`, `INCIDENT`) is **not** a status — it's `CANCELLED` plus metadata, or a `ride_events` entry:

- `cancelled_by`: `OWNER | PASSENGER | RIDER | SYSTEM`
- `cancel_reason` (fixed enum, not free text): `OUTSIDE_SERVICE_AREA, NO_SHOW, OWNER_BUSY, OPERATING_HOURS, BREAKDOWN, UNSAFE_PICKUP, PAYMENT_TIMEOUT, PASSENGER_REQUEST, SYSTEM_TIMEOUT, FARE_DECLINED, REQUEST_TIMEOUT` *(finalize full list in Business Rules doc)*

Ride reaching its destination (`IN_PROGRESS → COMPLETED`) is **independent of payment status** — a `COMPLETED` ride with `payment_status = DISPUTED` or `FAILED` is a normal, valid, queryable state. The trip happened; the money is a separate concern.

Booking-flow detail within the active states:
- `REQUESTED` → (if outside operating hours or service radius: immediate `CANCELLED, cancelled_by=SYSTEM`, no request created)
- → `OWNER_REVIEWING` (or auto-classified as above)
- Owner rejects → `CANCELLED, cancelled_by=OWNER`
- → `FARE_SENT` → passenger declines → `CANCELLED, cancelled_by=PASSENGER, reason=FARE_DECLINED`
- → `FARE_ACCEPTED` → `RIDER_ASSIGNED` (auto-assigned if only one rider online + owner approved; manual selection if 2+ riders online — see note below)
- Rider rejects → owner notified, reassign
- → `RIDER_EN_ROUTE` → `ARRIVED` → passenger no-show after wait → `CANCELLED, cancelled_by=SYSTEM, reason=NO_SHOW` (+ passenger strike)
- → `IN_PROGRESS` (rider taps "Start Ride" → logs `ride_event = RIDE_STARTED` → DB trigger sets `ride.status = IN_PROGRESS`; never inferred from GPS proximity alone, since drift or an unrelated stop could falsely suggest rider and passenger are together) → `COMPLETED`

**Un-actioned requests must time out** — no status should be able to sit indefinitely without a system-driven resolution (see Configuration timeouts above).

**Documented V1 boundary — manual assignment at 2+ riders:** this is a deliberate scope decision, not a flaw to fix later. With multiple riders online, the owner has context no algorithm has today (who's about to go off duty, who's low on fuel, who knows a particular route, who already called in busy) — manual dispatch is the *correct* operational choice at this scale, not a stopgap. Auto-dispatch/nearest-rider logic becomes worth building only if the business grows well beyond a handful of riders; until then, this isn't a bottleneck to eliminate, it's how the owner actually runs the business.

---

## Payment Lifecycle (fully independent of ride status)

`rides` table carries the **current truth**: `payment_status (PENDING | SUCCESS | FAILED | DISPUTED)`, `refunded (boolean, default false)`, `refunded_at (nullable)`.

`payment_events` is the **append-only history**: every STK attempt, wrong PIN, retry, cash confirmation, dispute, refund record, etc. A **database trigger** on `payment_events` updates `rides.payment_status` automatically — the only way payment status changes is by logging an event; application code cannot let them drift apart.

**Invariant, enforced by a CHECK constraint (not application code):**
```sql
CHECK (refunded = false OR payment_status = 'SUCCESS')
```
A refund can only be marked true if the payment actually succeeded.

**No automated refund system in V1.** MPESA STK fires *before* the ride starts (post-fare-acceptance) — if a ride is later cancelled after payment succeeded, the owner manually refunds via his own MPESA app and logs it in Operations Center (`payment_events: REFUND_RECORDED`), then sets `refunded = true`. No Daraja B2C integration, no `REFUND_PENDING` state.

**Preferred vs. Actual payment method:** passenger selects a *preference* at booking (not a binding method) — `preferred_payment_method`, `actual_payment_method`, `payment_method_changed (boolean)`, `payment_change_reason`. Either party can switch before the ride is marked `SUCCESS`; once `SUCCESS`, the method is locked (corrections happen via new records, not edits).

**Payment accounts:** owner configures MPESA Till/Paybill/Personal once in Settings, marks a default. If no default active payment account is configured, MPESA is unavailable for new rides and only Cash is offered until the owner configures one. STK pushes go automatically to the *passenger's registered phone number* — no manual entry. Override: "Pay with another number" for one-off cases (e.g. paying from a relative's line) — the temporary number is logged on that payment record only, never overwrites the passenger's account.

**MPESA timeout:** query Daraja's STK status before treating a timeout as failure (callbacks can lag). Passenger sees Retry / Switch to Cash on failure.

---

## Events (`ride_events`, `payment_events`, `sos_alerts`)

Events are immutable and ordered by creation time — they represent the authoritative audit trail for every ride. Each event table has its own fixed enum, not free text:

**`ride_event_type`** (`ride_events`): `RIDE_REQUESTED, OWNER_REVIEWED, FARE_SENT, FARE_ACCEPTED, RIDER_ASSIGNED, RIDER_ACCEPTED, RIDE_STARTED, ARRIVED, NO_SHOW, ROUTE_DEVIATION, RIDE_COMPLETED, RIDE_CANCELLED, BREAKDOWN, ACCIDENT, SOS_TRIGGERED, SOS_RESOLVED, SHARE_RIDE_CREATED, OWNER_NOTE`

**`payment_event_type`** (`payment_events`): `PAYMENT_ATTEMPT, PAYMENT_SUCCESS, PAYMENT_FAILED, PAYMENT_DISPUTED, REFUND_RECORDED`

These are separate enums — each table enforces its own set of valid values at the database level.

Incidents (breakdown, accident) are **events, not ride statuses**. If the ride continues (replacement rider), status stays in the active flow; if it can't continue, status becomes `CANCELLED` with the appropriate reason.

---

## SOS

- Available from `RIDER_ASSIGNED` through payment resolution (not just `IN_PROGRESS`) — a passenger waiting alone for an assigned rider is also at risk.
- Persistent floating button, positioned clear of map zoom/recenter controls.
- Passenger or rider triggers → confirmation → select emergency type (Robbery, Medical, Accident, Harassment, Vehicle Breakdown, Other) → logs ride ID, user ID, GPS, time, type → `sos_alerts.status = ACTIVE`.
- High-priority, persistent push to the owner (loud/foreground alert). V1 has **no SMS/call escalation** — this limitation is explicit and documented, not silent.
- Multiple simultaneous alerts: priority queue by severity first, then oldest-first within the same severity.
- Owner can call the person, open navigation to their location, or mark resolved with notes.

**Owner-triggered SOS (owner riding as a rider):** notifying "the owner" is meaningless when the owner is the one in danger — the Operations Center *is* the owner. V1 deliberately does **not** build emergency-contact escalation for this case: an unconscious or robbed owner isn't opening the app to press a button anyway, so infrastructure built for that moment has no real user. Instead, when the owner (logged in as Rider) presses SOS, the system simply **logs the event** — GPS, ride ID, timestamp — same as any other `sos_alerts` entry, with no further notification chain. The value is after-the-fact: an accurate record of what happened, when, where, and on which ride. If the owner later requests automatic family/contact notification for this specific case, that becomes a deliberate V2 feature request — not a gap being retrofitted speculatively now.

---

## Share Ride (V1)

- One `share_token` (long random string, not the `ride_id`) per ride, auto-created at `RIDER_ASSIGNED`.
- Public, unauthenticated FastAPI endpoint: `GET /share/{token}` → token exists? → ride still active (non-terminal)? → return limited data only (rider name/photo/plate/rating, live position, ETA, coarse status). Never phone numbers, payment info, or ride history.
- Live updates via polling the same endpoint every 5–10s — **not** Supabase Realtime (would require exposing anonymous RLS access, a much larger security surface for one convenience feature).
- Token invalidated (not deleted — `active=false, expired_at=timestamp`, kept for audit) on **any** terminal ride state, not just `COMPLETED`.
- Dedicated per-IP rate limit on this endpoint, since it's the one path with no login.
- Business Emergency Contacts (owner's own escalation contacts) deferred to V2 — different concept from this passenger-facing feature, and was correctly split out.

---

## Cash Handling

- Rider confirms `Cash Received` in-app before a ride can close on the cash path; passenger refusing → `payment_status = DISPUTED`, owner notified, dispute stays open until resolved (business policy, not code, governs the resolution).
- **End-of-day Cash Handover:** when a rider goes offline, they complete a handover, recorded as its own financial entity (not just a status flag) — `cash_handovers: id, rider_id, expected_cash, actual_cash, difference, received_by, created_at` — comparing cash collected per completed rides vs. cash actually handed to the owner and flagging discrepancies. Cash handovers are append-only and never edited after creation; corrections are recorded as new adjustment entries, same as every other financial record in the system.

---

## Suspension & Strikes

Owner can suspend a Passenger or Rider for: repeated no-shows, payment refusal, fake bookings, harassment, fraud, dangerous behaviour, SOS misuse. Suspended users cannot use the platform. Strike count is what feeds the Restricted Booking check above.

---

## Special Situations (quick reference)

| Situation | Resolution |
|---|---|
| Passenger cancels before assignment | Free, no strike |
| Passenger cancels after assignment | Reason required, possible strike |
| Rider cancels | Allowed reasons: breakdown, emergency, unsafe pickup, accident, personal emergency → reassign or cancel |
| Rider breakdown mid-ride | Event logged; owner sends replacement (stays active) or cancels (`CANCELLED, reason=BREAKDOWN`) |
| Network loss | Ride state, GPS, SOS, payment state cached locally, auto-sync on reconnect |
| Phone battery dies | Last known location retained; owner notified if ride goes inactive unexpectedly |
| GPS denied | Falls back to Places / Drop Pin, never a dead end |
| Outside service radius | Rejected immediately, friendly message, no request created |
| Outside operating hours | Rejected immediately (BR-021); passenger can call owner directly for exceptions |

---

## Open Items Still Needing a Number, Not Just a Rule

These are places where the *behavior* is decided but a concrete default value hasn't been picked yet — needed before Phase 1 build:
- Restricted Booking strike threshold default
- Owner-review / fare-response / rider-accept / MPESA-STK timeout durations
- No-show wait time before a driver can report it
- Stale-queue-request expiry window
- Share-link public endpoint rate limit (a number was proposed — 60 req/min/IP — confirm as final)
- Full, finalized `cancel_reason` and `dispute_reason` enum lists (drafts exist above and in earlier discussion, need one canonical list in `business_rules.md`)

---

## V1 Freeze

No additional entities, workflows, or business features may be introduced into the V1 specification unless they resolve:

- a contradiction,
- a data integrity issue,
- a security issue, or
- a real operational requirement stated by the business owner.

Feature requests that don't satisfy one of those conditions are automatically deferred to V2. This paragraph exists specifically to protect the project from scope creep — including scope creep introduced by an AI agent (this one included) proposing "improvements" during implementation.
