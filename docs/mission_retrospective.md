# Mission Retrospective & Engineering History
## Mission: Standardization on Supabase Auth & Google Auth Deprecation

### 1. Overview & Context
- **Date**: 2026-08-06
- **Scope**: Migration of 7s TOMS authentication system from custom Google OAuth ID token verification & custom local JWT to Supabase Auth (`supabase_flutter` SDK + GoTrue).
- **Status**: **CERTIFIED & COMPLETED**

---

### 2. Discovered Vulnerabilities & Fixes Accepted

| ID | Category | Vulnerability Discovered | Fix Accepted & Implemented |
|---|---|---|---|
| **VULN-001** | **Identity Fragmentation** | Dual identity management (`google_id` vs email password hashes) created account linking edge cases and unverified email scenarios. | Deprecated `google_id` column and `/api/v1/auth/google` endpoint. Standardized identity strictly on Supabase Auth. |
| **VULN-002** | **DB Row Level Security Gap** | Local custom JWT tokens signed by FastAPI did not populate `auth.uid()` in PostgreSQL context, bypassing native Supabase RLS policies. | Standardized JWT signature validation against `SUPABASE_JWT_SECRET`, extracting `auth.uid()` from the `sub` claim. |
| **VULN-003** | **Native Dependency Bloat** | `google_sign_in` plugin required native Android SHA-1 keystore signatures and iOS URL schemes, introducing build failures. | Replaced `google_sign_in` with `supabase_flutter: ^2.8.0` SDK. |

---

### 3. Proposals Considered & Rejected

1. **Idea**: Retain `/api/v1/auth/google` endpoint as a legacy fallback.
   - *Rejected because*: Violates Rule 7 (YAGNI / Dead Code) and Rule 10 (Delete Before Create). Leaving dead authentication endpoints creates security blindspots.
2. **Idea**: Hardcode `SUPABASE_ANON_KEY` or `SUPABASE_SERVICE_ROLE_KEY` inside Flutter code.
   - *Rejected because*: Violates Rule 11 (Security Is Never Optional). Service Role keys grant full admin bypass of RLS policies and must never be exposed client-side.

---

### 4. Known Accepted Risks & Residual Risks

1. **Stateless Supabase JWT Revocation Delay**:
   - *Residual Risk*: LOW.
   - *Explanation*: Supabase JWT access tokens have a short TTL (15 minutes). Revocation takes effect upon token expiration or active refresh token invalidation.
2. **Dashboard Configuration Dependency**:
   - *Residual Risk*: LOW.
   - *Explanation*: Production deployment requires the owner to populate `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `SUPABASE_JWT_SECRET` in `.env`.

---

### 5. Lessons Learned for Future Gates
- **Database Trigger Sync**: Automatic sync from `auth.users` to `public.users` via `ON CONFLICT (id) DO UPDATE` ensures seamless profile provisioning without race conditions.
- **Contract Enforcement**: Removing deprecated properties across all layers (schemas, endpoints, repositories, mobile screens, tests) prevents silent type rot.
