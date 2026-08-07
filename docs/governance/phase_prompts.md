# 7s — Master Implementation Prompts (Recovery + Remaining Phases)
Paste the Stack Lock once per session. Then paste ONLY the one prompt you're working on. Bring the full response back for verification before starting the next one.

---

## STACK LOCK (paste at the start of every session, every phase)

FROZEN STACK (Document 4, Section 1) — do not substitute, ever:
- Frontend (mobile): Flutter / Dart
- Backend: Python / FastAPI
- Database: PostgreSQL via Supabase
- Maps: OpenStreetMap + OpenRouteService (dev), evaluate Google before launch
- Payments: BambaStack M-Pesa Gateway
- Push: Firebase Cloud Messaging

If you are about to propose HTML/CSS/JS, React, Node, Vue, Angular, or
ANY frontend technology other than Flutter/Dart — STOP. Not an option
on this project. Flag a stack-change recommendation and wait for
approval; never silently substitute and continue as if agreed.

Golden rule: Flutter -> FastAPI -> Supabase. Flutter/Dart contains
UI, state, and API calls only. All business logic lives in FastAPI.
rides.status and rides.payment_status are never written directly by
application code — only via event insert + database trigger.

PROCESS RULE: Use Document 4's actual Stage numbering (Stage 1-6)
for anything related to build order. Do not invent your own naming
scheme ("Gates," "Missions," custom rule numbers, named protocols,
etc.) on top of it — every layer of invented terminology is another
thing that can drift from the real specification. If you want a
tracking mechanism, use the Stage names that already exist.

---

## CURRENT STATUS — READ THIS FIRST

Build order got violated: Stage 1 (Ride Engine) was only partially
built, then Stage 3 (Auth) and Stage 4 (Realtime) were implemented
out of order, skipping Stage 2 (Places/Maps) entirely. Stage 5
(Payments) and full Stage 6 (Reports) are also not built.

Existing files (per last report): auth.py, rides.py,
ride_websockets.py.
Missing: Places/Maps, Fare Templates, Payments, SOS, full Reports.

**Do not build anything new (no "Riders," "Users," or other
management endpoints) until the Recovery Prompt below is run and
Stage 2 is genuinely complete.**
