# 7s — Endpoint Inventory

Bridge between specification documents and OpenAPI contract. Every endpoint maps to its authorizing Business Rule and workflow step.

---

## Auth

| POST | `/api/v1/auth/register` | Any | No | BR-001 | Register with Email & Password |
| POST | `/api/v1/auth/login` | Any | No | BR-001 | Sign in with Email & Password |
| POST | `/api/v1/auth/google` | Any | No | BR-001 | Sign in / register via Google Sign-In |
| POST | `/api/v1/auth/forgot-password/request` | Any | No | BR-001 | Request 6-digit OTP for email password reset |
| POST | `/api/v1/auth/forgot-password/verify-otp` | Any | No | BR-001 | Verify 6-digit OTP for email password reset |
| POST | `/api/v1/auth/forgot-password/reset` | Any | No | BR-001 | Reset password with verified 6-digit OTP |
| POST | `/api/v1/auth/refresh` | Any | Yes | BR-002 | Refresh expired JWT |

## Rides

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| POST | `/api/v1/rides` | Passenger | Yes | BR-005, BR-027 | Create ride request (runs booking classification) |
| GET | `/api/v1/rides` | All | Yes | — | List rides (scoped by role) |
| GET | `/api/v1/rides/{id}` | Participant | Yes | — | Get ride details |
| PATCH | `/api/v1/rides/{id}/review` | Owner | Yes | BR-007 | Accept/reject request + set fare |
| PATCH | `/api/v1/rides/{id}/fare-response` | Passenger | Yes | BR-007 | Accept or decline fare |
| PATCH | `/api/v1/rides/{id}/assign` | Owner | Yes | BR-008, BR-026, BR-028 | Assign rider to ride |
| PATCH | `/api/v1/rides/{id}/accept` | Rider | Yes | BR-008 | Rider accepts assigned ride |
| PATCH | `/api/v1/rides/{id}/reject` | Rider | Yes | BR-008 | Rider rejects assigned ride |
| PATCH | `/api/v1/rides/{id}/en-route` | Rider | Yes | BR-009 | Rider starts heading to pickup |
| PATCH | `/api/v1/rides/{id}/arrive` | Rider | Yes | BR-009 | Rider arrives at pickup |
| PATCH | `/api/v1/rides/{id}/start` | Rider | Yes | BR-009 | Start ride (explicit tap, not GPS) |
| PATCH | `/api/v1/rides/{id}/complete` | Rider | Yes | BR-009 | Complete ride |
| PATCH | `/api/v1/rides/{id}/cancel` | All | Yes | BR-020 | Cancel ride (requires reason) |
| GET | `/api/v1/rides/{id}/events` | Participant | Yes | BR-022 | Get ride event timeline |

## Payments

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| POST | `/api/v1/rides/{id}/payment/stk-push` | Passenger | Yes | BR-010, BR-035 | Initiate MPESA STK push |
| POST | `/api/v1/rides/{id}/payment/cash-confirm` | Rider | Yes | BR-011 | Confirm cash received |
| POST | `/api/v1/rides/{id}/payment/dispute` | Rider | Yes | BR-011 | Flag payment dispute |
| POST | `/api/v1/rides/{id}/payment/refund` | Owner | Yes | BR-010 | Record manual refund |
| GET | `/api/v1/rides/{id}/payment/events` | Participant | Yes | BR-022 | Get payment event history |
| POST | `/api/v1/webhooks/mpesa/callback` | System | No* | BR-010 | Daraja callback (IP-validated) |

*\*Authenticated by IP allowlist + payload validation, not JWT.*

## Places

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| GET | `/api/v1/places` | All | Yes | BR-014 | List places (filtered by type, scoped by role) |
| POST | `/api/v1/places` | All | Yes | BR-014 | Create a place (USER/OWNER/SYSTEM per role) |
| PATCH | `/api/v1/places/{id}` | Owner | Yes | BR-014 | Update place (owner only for SYSTEM/OWNER) |
| DELETE | `/api/v1/places/{id}` | Owner/Creator | Yes | BR-014, BR-024 | Soft-delete place |

## Fare Templates

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| GET | `/api/v1/fare-templates` | All | Yes | BR-006 | List active fare templates |
| POST | `/api/v1/fare-templates` | Owner | Yes | BR-006 | Create fare template |
| PATCH | `/api/v1/fare-templates/{id}` | Owner | Yes | BR-006 | Update fare template |
| DELETE | `/api/v1/fare-templates/{id}` | Owner | Yes | BR-040 | Deactivate (soft-delete) fare template |

## SOS

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| POST | `/api/v1/sos` | Rider/Passenger | Yes | BR-012 | Trigger SOS alert |
| GET | `/api/v1/sos` | Owner | Yes | BR-012 | List active SOS alerts (priority-ordered) |
| PATCH | `/api/v1/sos/{id}/resolve` | Owner | Yes | BR-012 | Resolve SOS with notes |

## Share Ride

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| GET | `/api/v1/share/{token}` | Public | **No** | BR-013 | Get limited ride tracking data (rate-limited) |

## Riders

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| PATCH | `/api/v1/riders/me/online` | Rider | Yes | BR-003 | Go online (requires id_verified) |
| PATCH | `/api/v1/riders/me/offline` | Rider | Yes | — | Go offline |
| POST | `/api/v1/riders/me/location` | Rider | Yes | BR-032 | Update current location |
| POST | `/api/v1/riders/me/handover` | Rider | Yes | BR-011 | Submit end-of-day cash handover |

## Users (Owner Management)

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| GET | `/api/v1/users` | Owner | Yes | — | List all users |
| GET | `/api/v1/users/{id}` | Owner | Yes | — | Get user details |
| PATCH | `/api/v1/users/{id}/suspend` | Owner | Yes | BR-004 | Suspend user |
| PATCH | `/api/v1/users/{id}/unsuspend` | Owner | Yes | BR-004 | Unsuspend user |
| PATCH | `/api/v1/users/{id}/strike` | Owner | Yes | BR-019 | Add strike to user |
| PATCH | `/api/v1/riders/{id}/verify` | Owner | Yes | BR-003 | Mark rider as ID-verified |

## Ratings

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| POST | `/api/v1/rides/{id}/rate` | All | Yes | BR-033 | Submit rating (within 24h window) |

## Configuration

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| GET | `/api/v1/config` | Owner | Yes | BR-039 | Get all configuration values |
| PATCH | `/api/v1/config` | Owner | Yes | BR-039 | Update configuration values |

## Reports

| Method | Endpoint | Role | Auth | BR | Description |
|---|---|---|---|---|---|
| GET | `/api/v1/reports/revenue` | Owner | Yes | BR-023 | Revenue summary (backed by `revenue_summary` view) |
| GET | `/api/v1/reports/riders` | Owner | Yes | — | Rider performance (backed by `rider_performance` view) |
| GET | `/api/v1/reports/cash` | Owner | Yes | — | Cash reconciliation (backed by `cash_reconciliation` view) |
| GET | `/api/v1/reports/dashboard` | Owner | Yes | — | Owner dashboard snapshot (backed by `owner_dashboard` view) |
| POST | `/api/v1/operations/cash-handovers` | Owner | Yes | BR-011 | Create cash handover record |

---

**Total: ~45 endpoints** across 11 groups.
