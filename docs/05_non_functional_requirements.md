# 7s — Non-Functional Requirements
Security, Rate Limiting, and Scalability policy. Written before code, so every future migration, endpoint, and Flutter screen can be checked against it.

---

## 1. Security

### Authentication
- Primary authentication via Google Sign-In, Facebook Login, Apple Sign-In (iOS), and Email + Password. Phone numbers are strictly payment MSISDNs.
- 6-digit OTP sent to verified email for self-service password resets.
- JWT issued on successful sign-in; every backend request carries it.
- Owner/Rider/Passenger/Admin claims are server-side enforced — never inferred client-side.

### The client never holds a privileged key
- Flutter app talks to your FastAPI backend, not directly to Supabase for anything involving business rules (strike checks, fare template logic, payment initiation). This mirrors the pattern you already run on VigilantEdge, and for the same reason: business rules (booking type decision, strike thresholds, fare template matching) need to live in one place, not be duplicated in Flutter and re-validated hopefully-correctly by RLS.
- Supabase RLS is still your *last line of defense* — every table gets RLS even though the backend is the primary gate. Two locks, not one.
- Secrets that must never leave the backend `.env`:
  - Supabase **service role** key
  - Daraja (MPESA) consumer key/secret
  - Africa's Talking API key
  - Google Maps API key (if/when adopted) — restrict by backend IP anyway, don't ship it in the Flutter build

### Server-side validation, always
- Service radius check happens again on the backend, not just in the Flutter map UI. A modified client or direct API call must not be able to submit a pickup outside the boundary.
- Strike threshold and booking-type decision (Instant/Manual/Restricted) computed server-side from the DB, never trusted from client input.
- GPS coordinates sanity-checked (valid lat/lng ranges, not null-island 0,0 — a common bug signature from denied-permission clients).

### Payment integrity
- Daraja callback webhook: verify the request actually originates from Safaricom (IP allowlist if Daraja supports it, plus validate the payload shape) before trusting a "payment success."
- Store the full raw callback (`payment_events.raw_callback`) — this is your evidence of record for disputes, not just the parsed status.
- Idempotency key on STK push = `ride_id`, so a retried request can't double-charge or double-confirm.

### Logging hygiene
Debug/verbose logging is the most common way secrets leak in practice — not through a deliberate mistake, but through someone flipping on verbose logging to chase down a bug and forgetting to scope it. State it explicitly, not just "developers should know better":
- Never log JWTs or session tokens in full
- Never log OTP codes, even in debug/dev environments
- Never log Daraja consumer secrets, API keys, or the raw payment account credentials
- Redact phone numbers in logs where practical (last 4 digits is usually enough for debugging)

### Data handling
- No hard deletes on `ride_events`, `payment_events`, `sos_alerts` — audit trail integrity matters more than storage cost at this scale.
- One-time location-tracking consent at signup (Kenya Data Protection Act relevant here, given continuous GPS storage).
- `USER`-type places (personal saved locations) are private to their creator via RLS — never globally readable like `SYSTEM`/`OWNER` places.

---

## 2. Rate Limiting

This protects two different things: your money (paid API calls) and your users (abuse).

### Cost-driving APIs
- **Routing (OSM/Google)**: cache the distance/ETA result whenever both endpoints are `SYSTEM`/`OWNER` places — a Fare Template match means you already know the fare, so you shouldn't be re-querying routing at all in that path. Only uncached, ad-hoc pin-to-pin requests hit the routing API live.
- **MPESA STK push**: cap retries per ride (e.g. 3 attempts) before forcing a switch to cash — protects against a passenger (or a bug) hammering Daraja.
- **SMS (Africa's Talking)**: only fired on defined events (login OTP, SOS escalation) — never on a loop a client could trigger repeatedly.

### Abuse protection
- Ride requests: cap per passenger per hour (e.g. 5) — throttles fake-booking spam without affecting a real customer's normal usage.
- Login OTP requests: standard cooldown between resend attempts (e.g. 60s) to prevent SMS-bombing a phone number.
- SOS: **never rate-limit or block** — false positives here are a safety risk, not a cost problem. Instead, log repeated SOS from the same account and let the owner review the *pattern* manually (ties to your existing "SOS misuse" suspension reason) rather than the system auto-suppressing alerts.

### Implementation
- FastAPI-level limiter (e.g. `slowapi`) keyed by user ID (not just IP — a shared IP shouldn't throttle unrelated users, and a single abusive user on rotating IPs shouldn't evade it).

---

## 3. Scalability

Not because you need scale on day one — because retrofitting these is expensive and doing them now is nearly free.

### Database
- Index `rides.status`, `rides.passenger_id`, `rides.rider_id`, `rides.created_at` — every dashboard query filters on these.
- `places.latitude`/`places.longitude` — if usage grows past simple radius checks, PostGIS (`geography` type + `ST_DWithin`) is a straightforward upgrade from manual lat/lng math. Not needed for V1's simple circle check.
- Partition or archive old `rides`/`ride_events` rows once volume grows — not a V1 concern, just don't design anything that assumes the table stays small forever (e.g. no `SELECT *` full-table scans in reporting queries).

### Background jobs (you'll need these from Phase 1)
Timeouts and expirations don't run themselves — something has to check and act:
- Stale `IN_OWNER_QUEUE` requests past their expiry window
- MPESA STK timeout → status query
- Rider-assignment timeout → reassignment

A simple scheduled job (Supabase Edge Function on a cron, or a lightweight worker loop in your FastAPI service) checking these every 15–30s is enough at this scale — no need for a full job queue system (Celery, etc.) yet.

### Realtime
- Scope Supabase Realtime subscriptions **per ride** (channel per `ride_id`), not one global channel — keeps payload size and client-side filtering minimal as ride volume grows, and it's the same cost either way to build correctly now vs. refactor later.

### What NOT to build yet
- No caching layer (Redis etc.) beyond simple in-app query result caching — premature at this volume.
- No read replicas, no multi-region — single Supabase instance is correct for a one-town business.
- No horizontal scaling of the backend — a single FastAPI instance handles this comfortably; revisit only if request volume actually demands it.

---

*This doc governs implementation decisions, same role as `business_rules.md` — when in doubt, check here before writing infra code.*
