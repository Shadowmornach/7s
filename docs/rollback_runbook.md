# 7s TOMS — Emergency Rollback Runbook (Pilot Phase)

> **Scope**: Authoritative procedures for reverting database migrations, rolling back the FastAPI backend service, and executing emergency incident escalation during live pilot operations in Voi.

---

## 1. Database Migration Rollback

If a database migration introduces schema incompatibilities or trigger failures:

1. **Check Applied Migrations**:
   ```bash
   supabase migration list
   ```

2. **Revert Schema to Target Version**:
   Execute the migration reset to the last verified stable version timestamp:
   ```bash
   supabase db reset --version <prior_stable_timestamp>
   ```
   Or execute a targeted SQL reversion script against the database:
   ```bash
   psql "$DATABASE_URL" -f supabase/migrations/revert_<migration_name>.sql
   ```

3. **Verify Schema & Policy Health**:
   Confirm all primary tables and RLS policies are intact:
   ```sql
   SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
   ```

---

## 2. FastAPI Backend Service Rollback (systemd + uvicorn)

The 7s backend is deployed directly to a Linux host running systemd and uvicorn in a virtual environment (`/opt/7s/backend`). **No Docker or Kubernetes containers are used.**

If a code release causes 5xx errors or service crashes:

1. **Revert Workspace Code to Previous Release**:
   Navigate to the backend deployment directory and checkout the previous stable Git release/tag:
   ```bash
   cd /opt/7s/backend
   git checkout HEAD~1
   ```

2. **Re-activate Virtual Environment & Verify Dependencies**:
   ```bash
   source /opt/7s/backend/venv/bin/activate
   pip install -r requirements.txt --quiet
   ```

3. **Restart the `7s-backend` Systemd Service**:
   ```bash
   sudo systemctl restart 7s-backend
   ```

4. **Verify Service Status & Logs**:
   ```bash
   sudo systemctl status 7s-backend
   sudo journalctl -u 7s-backend -n 50 --no-pager
   curl -i http://127.0.0.1:8000/ready
   curl -i http://127.0.0.1:8000/api/v1/health/preflight
   ```

---

## 3. Incident Escalation & Owner Emergency Protocol

If an unrecoverable system outage occurs during live pilot operations (e.g., active rides stuck, payment callback outage, or SOS trigger failure):

1. **Contact Information**:
   - **System Owner / Lead Rider**: 7s Owner
   - **Emergency Phone**: `+254 700 000 000` (Direct Cell / WhatsApp)
   - **Secondary Ops Contact**: `+254 711 000 111`

2. **Manual Operations Failover Protocol**:
   - Call/SMS the owner immediately to transition dispatch to direct phone calls.
   - All cash handovers revert to manual paper ledger recording until the backend is restored to `GREEN`.
