# 7s — Decision Log

Architectural and design decisions made during the specification phase. Indexed for quick lookup when someone asks "why didn't we just..."

---

| ID | Decision | Reason | Date | Documents |
|---|---|---|---|---|
| DL-001 | No per-ride OTP — login OTP only | Too much friction for a motorcycle taxi in a small town; rider identity verified at assignment, not per trip | 2026-07-24 | BR-002 |
| DL-002 | Flutter → FastAPI → Supabase (never direct) | Business rules must live in one place; Supabase RLS is a second lock, not the primary gate | 2026-07-24 | Doc 4 §1, NFR §1 |
| DL-003 | Manual refunds only — no Daraja B2C in V1 | Integration complexity not justified at this volume; owner uses personal MPESA app | 2026-07-24 | BR-010, BP-003 |
| DL-004 | Manual rider assignment when 2+ riders online | Owner has context no algorithm has (fuel, fatigue, route familiarity); auto-dispatch is V2 | 2026-07-24 | Doc 1, BR-008 |
| DL-005 | Ride status and payment status are independent | A completed ride with a disputed payment is a valid state; the trip happened, the money is separate | 2026-07-24 | BR-009, BR-010 |
| DL-006 | Events drive state via DB triggers — never direct writes | Prevents application code from creating state drift; single source of truth for audit | 2026-07-24 | BR-022, Doc 4 §3 |
| DL-007 | Two terminal statuses only (COMPLETED, CANCELLED) | DECLINED/REJECTED/EXPIRED are CANCELLED + metadata, not separate states | 2026-07-24 | BR-009, BR-020 |
| DL-008 | No SOS rate limiting — ever | False positives are a safety risk, not a cost problem; misuse handled by owner review + suspension | 2026-07-24 | BR-012, BP-009, NFR §2 |
| DL-009 | Share Ride uses polling, not Supabase Realtime | Realtime would require anonymous RLS — larger security surface for one convenience feature | 2026-07-24 | BR-013, Doc 1 |
| DL-010 | Owner-triggered SOS logs only — no notification chain | The owner IS the notification target; building family/contact escalation is V2 if requested | 2026-07-24 | Doc 1, BP-010 |
| DL-011 | Service area is circle (center + radius), not polygon | Polygon precision is unnecessary for one-town V1; circle is simpler to configure and validate | 2026-07-24 | BR-018, Doc 1 |
| DL-012 | Strikes never auto-suspend — always explicit owner action | Context matters; a phone dying isn't the same as deliberately avoiding payment | 2026-07-24 | BR-019, BP-004 |
| DL-013 | No partial payment mechanism in V1 | Keeping the payment model simple (status, not ledger); revisit if partial payments become frequent | 2026-07-24 | BP-002 |
| DL-014 | `OWNER_NOTE` stays in `ride_events` for V1 | Append-only stream is consistent; separate `ride_notes` table is a V2 refinement, not a defect | 2026-07-24 | Doc 4 §3 |
| DL-015 | Split event enums: `ride_event_type` + `payment_event_type` | Shared enum allowed impossible rows; separate enums let the DB enforce correctness | 2026-07-24 | Doc 4 §2 |
| DL-016 | BR-029 is a state graph, not a linear sequence | Instant Booking legitimately skips OWNER_REVIEWING/FARE_SENT/FARE_ACCEPTED; a graph is the correct model | 2026-07-24 | BR-029 |
| DL-017 | Concurrency control is a business rule (BR-041), not just a technical detail | "One rider per ride" and "one current state" are business invariants, not implementation preferences | 2026-07-24 | BR-041, BR-024 |
| DL-018 | API versioning (`/api/v1/`) from day one | Avoiding painful migrations later; zero cost to add now | 2026-07-24 | Doc 4 §5 |
| DL-019 | Supabase CLI for migrations, not Alembic | Single ecosystem; Supabase already manages Auth, Postgres, Realtime, Storage | 2026-07-24 | Doc 4 §9 |
| DL-020 | Mermaid as canonical diagram format | Git-diffable, AI-readable, GitHub-rendered natively; PNG/SVG generated from Mermaid, never edited directly | 2026-07-24 | Phase 2 |
| DL-021 | State-changing API responses return current ride state | Eliminates follow-up GETs, prevents stale-state race conditions in mobile clients | 2026-07-24 | Doc 4 §5 |
| DL-022 | Notifications never gate business transactions | Push server down ≠ ride creation fails; Firebase outage ≠ payment fails to record | 2026-07-24 | BR-015, Doc 1 |
| DL-023 | No SMS/call escalation for SOS in V1 | Documented limitation, not a silent gap; push notifications only | 2026-07-24 | BR-012, Doc 1 |
| DL-024 | Place search (autocomplete/geocoding) deferred past V1 | Routing (distance/ETA) is required; search is a separate concern that can wait | 2026-07-24 | Doc 1 |
| DL-025 | `ride_events.metadata` is intentionally schema-flexible (JSON) | Prevents nullable-column drift; fields only promoted to first-class columns when indexing demands it | 2026-07-24 | Doc 4 §3 |
| DL-026 | Conditional M-Pesa Phone Number Collection | Phone number is optional during signup/profile setup; requested only when user chooses M-Pesa payment method for the first time | 2026-08-01 | BR-001, BR-010 |
| DL-027 | Maps: `flutter_map` + OpenStreetMap Engine | Uses `flutter_map` with OpenStreetMap tile provider (`tile.openstreetmap.org`); free tier with zero API keys or paid billing required | 2026-08-01 | Doc 4 §4, pubspec.yaml |
| DL-028 | Google OAuth + Email/Password Auth Architecture | Replaced legacy phone OTP signup with Google Sign-In (server ID token validation) and Email/Password with JWT sessions; PASSENGER role only for self-service | 2026-08-01 | BR-001, BR-002, Migration 023 |
| DL-029 | Complete Deprecation of Phone OTP Auth & Email Password Reset Standard | Completely removed phone OTP authentication and SMS login endpoints from repository, database, and ERD. Identity is strictly anchored on Email/OAuth (Google, Facebook, Apple, Email+Password). Phone number is exclusively an operational M-Pesa payment MSISDN. 6-digit Email OTP implemented for Forgot Password resets. | 2026-08-02 | BR-001, Migration 027, ERD |

