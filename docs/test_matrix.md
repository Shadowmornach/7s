# 7s — BR → Test Matrix

Every business rule (BR-001 through BR-041) mapped to automated test cases. This is the acceptance checklist — the objective definition of "done."

---

## Schema Verification (FK, CHECK, UNIQUE)

| BR | Rule Summary | Test Type | Test Description | Priority |
|---|---|---|---|---|
| BR-001 | Unique phone number | DB | INSERT duplicate `users.phone_number` → must fail (UNIQUE) | High |
| BR-010 | Refund requires SUCCESS | DB | `UPDATE rides SET refunded=true WHERE payment_status='FAILED'` → must fail (CHECK) | Critical |
| BR-010 | Refund requires SUCCESS | DB | `UPDATE rides SET refunded=true WHERE payment_status='SUCCESS'` → must succeed | Critical |
| BR-024 | FK enforcement | DB | INSERT `ride_events` with non-existent `ride_id` → must fail (FK) | High |
| BR-024 | FK enforcement | DB | INSERT `rides` with non-existent `passenger_id` → must fail (FK) | High |
| BR-033 | One rating per ride per rater | DB | INSERT duplicate `ratings(ride_id, rated_by)` → must fail (UNIQUE) | Medium |
| BR-033 | Score range | DB | INSERT `ratings` with `score=6` → must fail (CHECK 1-5) | Medium |
| BR-033 | No self-rating | DB | INSERT `ratings` with `rated_by = rated_user` → must fail (CHECK) | Medium |
| BR-005 | Fare template place pair | DB | INSERT `fare_templates` with `from_place_id = to_place_id` → must fail (CHECK) | Medium |
| BR-006 | Positive fare | DB | INSERT `fare_templates` with `fare=0` → must fail (CHECK) | Medium |
| — | Coordinate sanity | DB | INSERT `rides` with `pickup_lat=91` → must fail (CHECK) | Medium |
| — | Null island prevention | DB | INSERT `places` with `lat=0, lng=0` → must fail (CHECK) | Medium |

---

## Trigger Verification (ride_events, payment_events)

| BR | Rule Summary | Test Type | Test Description | Priority |
|---|---|---|---|---|
| BR-022 | Status from events only | Integration | INSERT `ride_event(RIDE_STARTED)` on ride in ARRIVED → `rides.status` becomes IN_PROGRESS | Critical |
| BR-022 | Payment status from events | Integration | INSERT `payment_event(PAYMENT_SUCCESS)` → `rides.payment_status` becomes SUCCESS | Critical |
| BR-029 | Valid transition: Manual path | Integration | REQUESTED→OWNER_REVIEWING→FARE_SENT→FARE_ACCEPTED→RIDER_ASSIGNED → all succeed | Critical |
| BR-029 | Valid transition: Instant path | Integration | REQUESTED→RIDER_ASSIGNED (Instant Booking) → succeeds | Critical |
| BR-029 | Invalid skip | Integration | INSERT `ride_event(RIDE_STARTED)` on REQUESTED → must raise exception | Critical |
| BR-029 | Invalid skip | Integration | INSERT `ride_event(RIDE_COMPLETED)` on FARE_SENT → must raise exception | Critical |
| BR-029 | Terminal state final | Integration | INSERT `ride_event(RIDE_STARTED)` on COMPLETED → must raise exception | Critical |
| BR-029 | Terminal state final | Integration | INSERT `ride_event(RIDER_ASSIGNED)` on CANCELLED → must raise exception | Critical |
| BR-029 | CANCELLED from any active | Integration | INSERT `ride_event(RIDE_CANCELLED)` from each active state → all succeed | Critical |
| BR-029 | OWNER_NOTE on terminal | Integration | INSERT `ride_event(OWNER_NOTE)` on COMPLETED → must succeed (allowed exception) | High |
| BR-035 | No attempt after SUCCESS | Integration | INSERT `payment_event(PAYMENT_ATTEMPT)` when `payment_status=SUCCESS` → must raise exception | Critical |
| BR-035 | Dispute after SUCCESS OK | Integration | INSERT `payment_event(PAYMENT_DISPUTED)` when `payment_status=SUCCESS` → must succeed | High |
| BR-035 | Refund after SUCCESS OK | Integration | INSERT `payment_event(REFUND_RECORDED)` when `payment_status=SUCCESS` → must succeed | High |
| BR-013 | Share token auto-created | Integration | INSERT `ride_event(RIDER_ASSIGNED)` → `rides.share_token` is non-null, `share_token_active=true` | High |
| BR-013 | Share token invalidated | Integration | INSERT `ride_event(RIDE_COMPLETED)` → `share_token_active=false`, `share_token_expired_at` set | High |
| BR-041 | Concurrent assignment | Integration | Two simultaneous RIDER_ASSIGNED events for same ride → only one succeeds, other raises exception | Critical |
| BR-041 | Cancel vs. start race | Integration | Simultaneous RIDE_CANCELLED and RIDE_STARTED → only one succeeds | Critical |
| BR-041 | Version increment | Integration | Each successful state change increments `rides.version` by 1 | High |

---

## RLS Verification

| BR | Rule Summary | Test Type | Test Description | Priority |
|---|---|---|---|---|
| BR-014 | USER places private | RLS | Passenger A's saved place is invisible to Passenger B | High |
| BR-014 | USER places private | RLS | Owner cannot see Passenger A's USER places | High |
| BR-014 | SYSTEM/OWNER places public | RLS | All authenticated users can read SYSTEM and OWNER places | High |
| — | Ride isolation | RLS | Passenger A cannot read Passenger B's rides | High |
| — | Ride isolation | RLS | Rider can only read rides assigned to them | High |
| — | Owner sees all | RLS | Owner can read all rides, events, users | High |
| — | Event read-only | RLS | Non-service-role user cannot INSERT into ride_events | High |
| — | Config owner-only | RLS | Non-owner cannot read or update configuration | Medium |
| — | Payment events private | RLS | Passenger A cannot read Passenger B's payment events | High |

---

## API Verification (JWT, roles, idempotency)

| BR | Rule Summary | Test Type | Test Description | Priority |
|---|---|---|---|---|
| BR-002 | JWT required | API | Request without JWT → 401 Unauthorized | Critical |
| BR-002 | Role server-side | API | Passenger JWT calling owner-only endpoint → 403 Forbidden | Critical |
| BR-003 | Rider must be verified | API | Unverified rider calling `PATCH /riders/me/online` → 403 | High |
| BR-004 | Suspended passenger | API | Suspended passenger calling `POST /rides` → 403 with clear message | High |
| BR-005 | Booking classification: suspended | API | Suspended passenger → immediate rejection, no ride created | Critical |
| BR-005 | Booking classification: restricted | API | Passenger with 2+ strikes, template match → OWNER_REVIEWING (not Instant) | Critical |
| BR-005 | Booking classification: instant | API | Template match, 0 strikes → RIDER_ASSIGNED (skips owner review) | Critical |
| BR-005 | Booking classification: manual | API | No template match → OWNER_REVIEWING | Critical |
| BR-008 | Rider response timeout | API | No rider response within 60s → system treats as rejection | High |
| BR-009 | Ride independent of payment | API | `rides.status=COMPLETED` with `payment_status=DISPUTED` → valid queryable state | High |
| BR-013 | Share endpoint unauthenticated | API | `GET /api/v1/share/{token}` without JWT → 200 (limited data) | High |
| BR-013 | Share endpoint rate limited | API | 61st request in 60s from same IP → 429 Too Many Requests | High |
| BR-013 | Share never exposes private data | API | Share response contains no phone numbers, payment data, or ride history | Critical |
| BR-018 | Server-side radius check | API | POST /rides with pickup outside service radius → rejected (not just Flutter-side) | Critical |
| BR-020 | Cancellation requires reason | API | PATCH /rides/{id}/cancel without cancel_reason → 400 | High |
| BR-026 | One active ride per rider | API | Assign rider who already has an active ride → 409 Conflict | High |
| BR-027 | One active ride per passenger | API | POST /rides while existing ride is active → 409 Conflict | High |
| BR-028 | Owner self-assignment while riding | API | Owner assigns self while riding → 409 Conflict | High |
| BR-030 | Duplicate request handling | API | Same passenger, same route within 10s → returns existing ride, not new one | High |
| BR-033 | Rating window | API | Rating submitted 25 hours after completion → 400 (window expired) | Medium |
| BR-034 | Share token reactivation | API | Attempt to reactivate expired share token → 400 | Medium |
| BR-039 | Config change scope | API | Config change during active ride → active ride unaffected | Medium |
| — | Idempotent state changes | API | Retry an already-applied valid transition → 200 (no-op), not error | High |
| — | State-changing response | API | Every PATCH /rides/{id}/* returns current ride state + version | High |

---

## Business Logic Unit Tests

| BR | Rule Summary | Test Type | Test Description | Priority |
|---|---|---|---|---|
| BR-005 | Classification order | Unit | Classification runs: suspended → strikes → template, in that exact order | Critical |
| BR-006 | Template match requires Places | Unit | Dropped pin pickup/destination → no template match, even if coordinates match | High |
| BR-007 | Owner review timeout | Unit | Un-actioned request after 3 min → auto-cancel with SYSTEM_TIMEOUT | High |
| BR-007 | Fare response timeout | Unit | Unanswered fare after 5 min → auto-cancel with SYSTEM_TIMEOUT | High |
| BR-008 | Auto-assign single rider | Unit | 1 online verified rider → auto-assigned after owner approval | High |
| BR-008 | Manual assign multiple | Unit | 2+ online riders → no auto-assignment, owner must select | High |
| BR-010 | MPESA retry limit | Unit | 4th STK attempt → rejected, forced cash fallback | High |
| BR-010 | STK timeout → query status | Unit | 90s without callback → query Daraja before treating as failure | High |
| BR-011 | Cash path requires confirmation | Unit | Ride cannot close on cash without explicit rider confirmation | High |
| BR-017 | Operating hours gate | Unit | Request outside configured hours → immediate rejection | High |
| BR-018 | Radius check server-side | Unit | Pickup 25km from center (radius=20km) → rejected | High |
| BR-019 | Strike never auto-suspends | Unit | Reaching strike threshold → Restricted Booking, NOT suspension | High |
| BR-038 | Notification idempotency | Unit | Duplicate notification ID → safely ignored | Medium |
| BR-040 | Soft delete visibility | Unit | Deactivated place excluded from selection but visible in historical ride | Medium |

---

## Summary

| Category | Test Count | Critical | High | Medium |
|---|---|---|---|---|
| Schema Verification | 12 | 2 | 4 | 6 |
| Trigger Verification | 18 | 11 | 7 | 0 |
| RLS Verification | 9 | 0 | 8 | 1 |
| API Verification | 24 | 8 | 14 | 2 |
| Business Logic Unit Tests | 14 | 2 | 10 | 2 |
| **Total** | **77** | **23** | **43** | **11** |
