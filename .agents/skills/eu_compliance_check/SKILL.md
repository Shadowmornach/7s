---
name: eu_compliance_check
description: EU regulatory compliance check skill — GDPR (General Data Protection Regulation) & PECR (Privacy and Electronic Communications Regulations) auditing, consent mechanisms, telemetry/analytics tracking rules, data subject rights (DSAR/RTBF), cookie banners, and security invariants.
---

# EU Regulatory Compliance Skill (GDPR & PECR)

This skill provides comprehensive instructions, audit checklists, and code standards for verifying and enforcing compliance with the **EU General Data Protection Regulation (GDPR)** and the **Privacy and Electronic Communications Regulations (PECR)** across web, mobile, and backend architectures.

---

## 1. Regulatory Framework Overview

### General Data Protection Regulation (GDPR)
- **Data Minimization (Art. 5(1)(c))**: Collect only personal data that is strictly necessary for specified, explicit, and legitimate purposes.
- **Lawful Basis for Processing (Art. 6)**: Ensure every data processing activity relies on explicit consent, contractual necessity, legal obligation, or documented legitimate interest.
- **Data Subject Rights**:
  - **Right of Access / DSAR (Art. 15)**: Provide structured JSON/CSV data export for all personal user data.
  - **Right to Erasure / RTBF (Art. 17)**: Provide mechanism for account deletion with automated or scheduled data purging.
  - **Right to Rectification (Art. 16)** & **Restriction of Processing (Art. 18)**.
- **Security & Confidentiality (Art. 32)**: Mandatory encryption at rest (AES-256 / Supabase storage) and in transit (TLS 1.3 / HTTPS), hashed credentials, and zero excessive logging of PII.

### Privacy and Electronic Communications Regulations (PECR)
- **Cookies & Local Storage (Reg 6)**: Prior explicit opt-in consent is required before placing or reading non-essential cookies, device storage items, or analytics tracking identifiers.
- **Direct Marketing & Push Communications (Reg 22/23)**: Mandatory opt-in for promotional SMS, push notifications, or emails with clear unsubscribe/opt-out toggles.

---

## 2. Compliance Audit Checklist

### A. Data Collection & Telemetry
- [ ] **No Mandatory PII Excess**: Optional fields (e.g. phone numbers, avatar images) must never be enforced as required fields during signup or onboarding.
- [ ] **Explicit Consent**: Telemetry, location tracking, and analytics SDKs must respect explicit opt-in toggles.
- [ ] **Data Minimization**: Location tracking must be limited to active ride/delivery sessions, not background tracking without user knowledge and explicit permissions.

### B. Consent & Privacy Notice Governance
- [ ] **Terms & Privacy Acceptance**: Sign-up flows must require explicit user agreement to Terms of Service and Privacy Policy before account creation.
- [ ] **Granular Toggles**: Separate consent toggles for marketing communications vs. essential operational notifications.
- [ ] **Easy Consent Revocation**: Users must be able to change notification and tracking preferences in app settings at any time.

### C. Logging & Telemetry Hygiene (Art. 32)
- [ ] **Zero PII in Server Logs**: Verify loggers never print plain passwords, JWT secrets, raw credit card details, full phone numbers, or unmasked tokens.
- [ ] **Masking Rules**: Sanitize or truncate sensitive fields in structured JSON logs (`7s.http`, `7s.auth`).

### D. Data Subject Rights (DSAR & Deletion)
- [ ] **Data Export Endpoint**: GET `/auth/data-export` returning full user profile, preferences, and activity logs in machine-readable format.
- [ ] **Account Deletion Endpoint**: DELETE `/auth/account` executing immediate deactivation or scheduled soft-deletion purge pipeline.

---

## 3. Code Implementation Patterns

### Granular Consent Model (`UserSession`)
```dart
class UserConsentSettings {
  final bool essentialServices;   // Required for contract (Ride/Delivery)
  final bool analyticsTelemetry;   // PECR opt-in required
  final bool marketingPush;        // PECR opt-in required

  const UserConsentSettings({
    this.essentialServices = true,
    this.analyticsTelemetry = false,
    this.marketingPush = false,
  });
}
```

### Telemetry Opt-In Gate Pattern
```dart
void trackTelemetryEvent(String eventName, Map<String, dynamic> properties) {
  final consent = currentConsentSettings;
  if (!consent.analyticsTelemetry) {
    // Suppress non-essential telemetry tracking per PECR Reg 6
    return;
  }
  // Proceed with anonymized telemetry dispatch
}
```

### Log Masking Utility Pattern
```python
def mask_pii(data: dict) -> dict:
    masked = data.copy()
    if "phone_number" in masked and masked["phone_number"]:
        phone = masked["phone_number"]
        masked["phone_number"] = phone[:4] + "****" + phone[-2:] if len(phone) > 6 else "****"
    if "email" in masked and masked["email"]:
        parts = masked["email"].split("@")
        masked["email"] = parts[0][0] + "***@" + parts[1] if len(parts) == 2 else "***"
    return masked
```

---

## 4. Automated Compliance Verification Commands

Run ripgrep checks to audit PII leakage and verify consent gates across the codebase:

```bash
# Search for unmasked log statements printing phone or email
grep -rn "logger\." --include="*.py" | grep -iE "phone|email|password|token"

# Search for telemetry dispatches missing consent gates
grep -rn "telemetry" --include="*.dart" --include="*.py"

# Audit DSAR and Account Deletion endpoints
grep -rn "data-export\|account" --include="*.py"
```
