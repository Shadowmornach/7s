# 7s — Configuration Reference
## Document 6 (Living Implementation Document)

This is the canonical reference for every runtime-configurable value in the system. It maps directly to the `configuration` table — the backend reads `config.<key>`, never a hardcoded literal.

Unlike Documents 1–5 (frozen), this document is updated as the business owner adjusts values based on real operational experience.

---

## Authentication & Password Reset OTP

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `email_otp_expiry_minutes` | 10 | minutes | Email OTP validity window before expiry | BR-001 |
| `email_otp_max_attempts` | 5 | count | Max verification attempts per email OTP | BR-001 |
| `email_otp_cooldown_seconds` | 60 | seconds | Minimum wait between email OTP resend requests | BR-001 |

## Booking & Review

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `restricted_booking_threshold` | 2 | strikes | Strike count that triggers Restricted Booking | BR-005, BR-019 |
| `owner_review_timeout_seconds` | 180 | seconds | Owner must act on queued request within this window | BR-007 |
| `fare_response_timeout_seconds` | 300 | seconds | Passenger must accept/decline fare within this window | BR-007 |
| `rider_response_timeout_seconds` | 60 | seconds | Assigned rider must accept/reject within this window | BR-008 |
| `duplicate_request_window_seconds` | 10 | seconds | Same passenger + same route within this window = duplicate | BR-030 |
| `stale_request_expiry_seconds` | 900 | seconds | Hard max age for any non-terminal request in queues | BR-021 |

## Service Area & Operating Hours

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `service_center_lat` | -3.3962 | decimal | Center point latitude (Voi CBD) | BR-018 |
| `service_center_lng` | 38.5561 | decimal | Center point longitude (Voi CBD) | BR-018 |
| `service_radius_km` | 20 | km | Maximum distance from center for pickup/destination | BR-018 |
| `operating_hours_start` | 06:00 | HH:MM | Daily operating hours start (EAT) | BR-017 |
| `operating_hours_end` | 22:00 | HH:MM | Daily operating hours end (EAT) | BR-017 |

## Payment

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `mpesa_stk_timeout_seconds` | 90 | seconds | Wait for Daraja callback before querying status | BR-010 |
| `mpesa_max_retries` | 3 | count | Max STK push attempts per ride before forcing cash | BR-010 |

## Ride Operations

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `no_show_wait_seconds` | 300 | seconds | Rider must wait at pickup before reporting no-show | BR-021 |
| `rating_window_hours` | 24 | hours | Time after ride completion to submit a rating | BR-033 |

## Share Ride

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `share_endpoint_rate_limit` | 60 | req/min/IP | Public endpoint rate limit for `GET /share/{token}` | BR-013 |
| `share_poll_interval_seconds` | 10 | seconds | Recommended client poll interval (advisory, not enforced) | BR-013 |

## Rate Limiting

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `ride_requests_per_hour` | 5 | count | Max ride requests per passenger per hour | NFR §2 |

## Business Identity

| Key | Default | Unit | Description | Source |
|---|---|---|---|---|
| `business_name` | 7s Transport | text | Display name shown to passengers | Doc 1 |
| `business_phone` | *(owner sets)* | text | Contact number shown when business is closed | BP-012 |

---

## Usage in Code

```python
# Backend loads from configuration table
timeout = await config.get("owner_review_timeout_seconds")  # returns 180

# Never this:
timeout = 180  # ❌ hardcoded
```

```dart
// Flutter receives relevant config values from FastAPI
// at login / app startup, cached locally
final reviewTimeout = appConfig.ownerReviewTimeoutSeconds;
```

---

## Change Policy

Per BR-039: configuration changes affect only **future** ride requests, never rides already in progress at the time of the change.
