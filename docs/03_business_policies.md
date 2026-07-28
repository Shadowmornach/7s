# 7s — Business Policies (BP)
## Master Document 3 of 5

Business Policies define how the **owner** exercises discretion in situations the software cannot resolve algorithmically. Where Document 2 (Business Rules) defines what the system must always enforce, this document defines what a human must decide — and gives the owner (and anyone helping him operate the business) a consistent basis for those decisions.

The system's job in every situation below is to **log the facts accurately** (who, what, when, GPS, amounts) so the owner can decide well — never to make the decision itself.

---

### BP-001 — Payment Dispute Resolution
When a passenger refuses cash payment (`payment_status = DISPUTED`):
- The owner reviews the logged facts: ride details, fare, passenger history/strikes, driver's account.
- The owner may: accept a partial payment, waive the fare, pursue the passenger directly (call, in-person follow-up), or apply a strike/suspension.
- There is no automatic outcome — the system does not resolve disputes, escalate them, or apply consequences on its own. A strike (BR-019) is only ever an explicit owner action.
- Once resolved, the owner records the outcome as a note; `payment_status` updates accordingly (e.g. manually marked resolved/written-off — exact status handling per BR-010).

### BP-002 — Partial Payment
If a passenger can only pay part of the fare (e.g. "I only have KES 200" on a KES 350 fare):
- This is entirely the owner's/rider's call in the moment — accept partial, insist on full, or arrange to collect the balance later.
- The system has no partial-payment mechanism in V1 (per the earlier decision to keep the payment boolean/status model simple, not a ledger) — whatever amount is actually collected is what the rider/owner records as received; a shortfall is not separately tracked as a business object in V1.
- If this becomes frequent enough to be an operational problem, it's a signal to revisit the financial ledger decision (V2), not to patch around it in V1.

### BP-003 — Refund Procedure
Per BR-010: no automated refunds in V1. When a ride is cancelled after a successful MPESA payment:
1. Owner personally sends the refund via his own MPESA app.
2. Owner logs it in Operations Center (`REFUND_RECORDED` event + `refunded = true`).
3. There is no defined SLA for how fast this must happen in V1 — it's owner discretion, though prompt handling protects trust with passengers in a small-town market where reputation travels fast.

### BP-004 — Strike Issuance
Strikes (BR-019) are always an explicit owner decision, never automatic, even when an event that *could* justify one occurs (no-show, payment refusal, etc.):
- The owner reviews context before issuing — a passenger's phone dying isn't the same as deliberately avoiding payment.
- No fixed "three strikes" script is mandated in V1 — the strike threshold (BR-005/BR-019 default 2) governs when Restricted Booking kicks in, but *whether* a given incident earns a strike at all is owner judgment.
- Suspension (BR-004) is a separate, more serious step than a strike, and always requires explicit owner action.

### BP-005 — Fare Negotiation & Waivers
- The owner may waive or reduce a fare at his discretion (goodwill, regular customer, service issue) — the system does not prevent this, only records whatever fare the owner actually sets.
- For Instant Booking (Fare Template) rides, the owner is not obligated to honor the template fare in every circumstance (e.g. unusual conditions, detour) — he can override to Manual Booking pricing for that specific ride if needed.

### BP-006 — Owner-Rider Payment Disputes
Per the earlier architectural note: when the owner himself is the rider in a payment dispute, he is not a neutral party. No special software mechanism arbitrates this in V1 — it remains the owner's own judgment call, same as any other dispute, with the same audit trail (GPS, timestamps, fare) available to him if he wants to check himself against his own memory of the ride.

### BP-007 — No-Show Compensation
When a rider reports a passenger no-show (BR — logged as `NO_SHOW`, possible passenger strike):
- Whether the rider receives any compensation for the wasted trip (time, fuel) is entirely an internal owner-to-rider arrangement — the app does not calculate or issue any no-show fee in V1.
- If the owner wants to formalize this later (e.g. a fixed no-show fee charged to the passenger), that's a V2 feature requiring its own Business Rule.

### BP-008 — Harassment & Safety Complaints
- Rider-reported unsafe pickup, or passenger-reported harassment by a rider (or vice versa): the owner investigates using the logged event trail (SOS records, ride events, ratings/comments) and decides on suspension per BR-004.
- V1 has no formal complaint workflow beyond the owner reviewing logged events and communicating directly (call) with the parties involved — a structured in-app complaint/appeal process is a V2 consideration if this proves to be a frequent need.

### BP-009 — SOS Misuse
- A pattern of SOS presses that don't correspond to real emergencies (per owner review of logged events, e.g. repeated non-emergency triggers) is grounds for suspension (BR-004, "SOS misuse").
- The owner is trusted to distinguish a genuine emergency from misuse using the logged emergency-type selection and his own follow-up (calling the person) — the system never auto-flags or auto-restricts SOS access, since false positives here are a safety risk, not just an abuse-prevention inconvenience (per the earlier explicit decision never to rate-limit SOS).

### BP-010 — Owner-Triggered SOS (Owner Riding)
Per the earlier decision: the system only logs the event (GPS, ride, timestamp) with no notification chain. What the owner does in that moment — call a family member, call emergency services, handle it himself — is entirely his own judgment and outside the app's scope in V1. The logged record exists for after-the-fact reference (insurance, retelling, review), not real-time response coordination.

### BP-011 — Cash Handover Discrepancies
When a `cash_handovers` record shows `actual_cash ≠ expected_cash` (BR-011):
- The owner decides how to handle the shortfall or overage with the rider directly — the system flags the discrepancy but does not determine fault, apply consequences, or adjust any rider's standing automatically.
- Repeated discrepancies with the same rider are a pattern the owner can review from the handover history, and may factor into a suspension decision (BR-004) at his discretion.

### BP-012 — Operating Hours Exceptions
Per BR-017/BR-021: outside configured operating hours, no request is auto-created, but the passenger may call the owner directly.
- Whether the owner accepts an off-hours ride (emergency, regular customer, simply being available) is entirely his call, handled outside the app via that direct phone call — the app's role ends at "the business is currently closed, here's how to reach the owner directly."

### BP-013 — Service Area Exceptions
Requests outside the configured service radius are rejected immediately by the system (BR-018) with no exception path in the app itself. If the owner wants to serve a specific out-of-area request anyway, that also happens outside the app (direct arrangement by phone) — it does not create an in-app ride record, since the system's radius check is a hard rule (BR-018), not a soft suggestion.

---

## Relationship to Business Rules

Per BR-025 (Rule Precedence), Business Policies sit below Business Rules and Business Workflow — a policy decision can never override a data integrity, security, or workflow rule. Policies govern discretion *within* the boundaries Business Rules already enforce (e.g. the owner can waive a fare, but cannot make the system skip the strike-check-before-fare-template-match sequence in BR-005).

## Open Items

- No fixed dispute-resolution SLA defined (BP-001, BP-003) — deliberately left to owner judgment for V1; may warrant a guideline (not a hard rule) once real dispute volume is observed.
- Partial payment (BP-002) is explicitly out of scope for a formal mechanism in V1 — flagged as a V2 trigger if it becomes frequent.
- No-show compensation (BP-007) and structured complaint handling (BP-008) are both explicitly deferred, not designed, pending real operational need.
