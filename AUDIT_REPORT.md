# Ari Esthetician App — Requirements Audit Report

**Audit Date:** January 31, 2026  
**Author:** Kevin Doyle Jr. / Infinitum Imagery LLC  
**Scope:** Guest checkout directory sync, Health & Skin Disclosure, Required Acknowledgements, Cancellation policy, Account linking, Admin PDF preview/print. Backwards compatibility and non-breaking changes.

---

## Executive Summary

The app has **existing support** for client info (first/last/email/phone), directory sync (clients collection), appointment creation with legal compliance fields (terms, health disclosure, required acknowledgements, cancellation policy), and client appointments by email. **Gaps** vs. the stated requirements: (1) Guest directory sync is best-effort (errors caught, booking still succeeds); (2) Health disclosure is boolean-only—no “full answers” or “Not applicable” text; (3) Required acknowledgements and cancellation policy lack timestamps/version on the appointment record; (4) No explicit account linking (userId) on appointments/clients—history is email-based only; (5) Admin has no appointment-level preview/print PDF. This document details current data flows, gaps, risks, and backwards-compat concerns.

---

## A. Current Data Flows

### A.1 Guest Flow

| Step | Current Behavior |
|------|------------------|
| Entry | Welcome → Account Choice → “Continue as Guest” → `context.go('/booking')`. No auth; no userId. |
| Booking | ClientBookingScreen: service → date/time → client info (first, last, email, phone, notes) → Health & Skin Disclosure (checkboxes + optional notes) → Required Acknowledgements (4 checkboxes) → Terms & Conditions (checkbox) → Cancellation policy (checkbox) → Payment (if enabled) → Submit. |
| Submit | `_submitBooking()` builds AppointmentModel with client fields + termsAcceptanceMetadata, healthDisclosure, requiredAcknowledgments, cancellationPolicyAcknowledged; calls `_firestoreService.createAppointment(appointment)` for each service. |
| After create | `createAppointment` writes appointment to Firestore, then calls `_syncClientFromAppointment(appointment)`. Sync errors are **caught and logged**; appointment creation still succeeds (best-effort). |
| Confirmation | Navigate to `/confirmation/{appointmentId}`. Guest has no “My Appointments” (requires login). |

**Gap:** Directory sync is not mandatory; guest data can fail to persist to clients collection without failing the booking.

### A.2 Directory Sync (Clients Collection)

| Aspect | Current Behavior |
|--------|------------------|
| Canonical directory | Firestore `clients` collection. ClientModel: id, firstName, lastName, email, phone, tags, internalNotes, totalAppointments, completedAppointments, noShowCount, totalSpentCents, createdAt, updatedAt, lastAppointmentAt. No `userId` field. |
| When | After `createAppointment` (inside FirestoreService). |
| Logic | `_syncClientFromAppointment`: query clients by `email == appointment.clientEmail`; if found, update (fill empty name/phone, increment totalAppointments); else create new client. Match is **email-only**; no phone-based deduplication. |
| Reliability | Sync is in a try/catch; on failure, error is logged and rethrown but caller (createAppointment) catches and only logs—booking still succeeds. |
| Idempotency | Update path is idempotent (same email → update). Create path can duplicate if two bookings with same email race (two creates). |

**Gaps:** (1) Sync must be reliable (fail booking if directory sync fails). (2) Match by email and/or phone to avoid duplicates. (3) Validation: required fields and email/phone format must be enforced before submit (already in UI validators; ensure server-side or fail-fast).

### A.3 Appointment Creation

| Aspect | Current Behavior |
|--------|------------------|
| Data | AppointmentModel: clientFirstName, clientLastName, clientEmail, clientPhone, intakeNotes, startTime, endTime, serviceId, serviceSnapshot, status, deposit/tip/payment fields, createdAt, updatedAt, termsAcceptanceMetadata, healthDisclosure, requiredAcknowledgments, cancellationPolicyAcknowledged. No `userId`. |
| Form snapshot | Terms, health disclosure, required acknowledgements, and cancellation boolean are stored on the appointment at submission time. |
| Health disclosure schema | HealthDisclosure: booleans (hasSkinConditions, hasAllergies, etc.) + optional additionalNotes. No per-item “details” or “Not applicable” text. |
| Required acknowledgements | RequiredAcknowledgments: four booleans. No timestamps or version on the appointment. |
| Cancellation policy | Single boolean `cancellationPolicyAcknowledged`. No timestamp, policy version, or policy text hash. |

**Gaps:** (1) Health disclosure: support full answers (e.g. list applicable items or “Not applicable” text per item). (2) Acknowledgements: store timestamps/version. (3) Cancellation: store checked, timestamp, policy version or hash.

### A.4 Form Submissions

| Form | Stored On | Current |
|------|-----------|---------|
| Client info | Appointment + (best-effort) clients | First/last/email/phone on appointment; clients sync best-effort. |
| Health & Skin Disclosure | Appointment | Boolean flags + optional additionalNotes. |
| Required Acknowledgements | Appointment | Four booleans. |
| Terms & Conditions | Appointment | termsAcceptanceMetadata (accepted, UTC/local time, ip, userAgent, platform, osVersion). |
| Cancellation policy | Appointment | Boolean only. |

All form data is captured and written to the appointment document; the shortfalls are schema (full answers for health, timestamps/version for acknowledgements and cancellation) and reliability of directory sync.

### A.5 Account Creation / Login

| Flow | Current Behavior |
|------|------------------|
| Signup | AuthService.signUpWithEmailAndPassword: create Firebase user, set users/{uid} (email, role, createdAt, updatedAt). If role client: getOrCreateClient by email (create client with empty first/last/phone if not exists). No linking of **existing** guest appointments to new user. |
| Clients collection | No `userId` field. Client record created at signup has empty name/phone until first booking. |
| Appointments | No `userId` field. Queried by clientEmail only. |

**My Appointments (client_appointments_screen):** Loads `_clientEmail = currentUser.email`; uses `getAppointmentsByClientEmailStream(_clientEmail!)`. So **all appointments with that email** (including those created as guest) already appear—**provided the guest used the same email**. There is no explicit “linking” step; it’s implicit by email match.

**Gaps:** (1) Optional `userId` on appointments and clients for explicit linking and future queries by uid. (2) On signup (or a dedicated “Link my bookings” action), set userId on client doc and on all appointments where clientEmail (and optionally phone) match. (3) Strong match rules (e.g. email required; phone optional) to avoid incorrect merges. (4) Client history: support loading by userId when present, else by email (backwards compat).

### A.6 Admin Preview / Print

| Current | Gap |
|--------|-----|
| Admin Appointments: list/calendar, filters, status updates, create appointment. Appointment detail dialog shows client, date/time, service, status, deposit, notes, admin notes; actions: Update Status, Close. **No preview/print PDF.** | Requirement: In admin “Quick actions,” add ability to preview an appointment (including all forms/disclosures/acknowledgements) and print as PDF. PDF must include client identity, appointment details, full disclosure answers, acknowledgements and policy agreement, submission timestamps. |
| Admin Services: has full PDF export for services list. | N/A (appointment PDF is separate). |

---

## B. Gaps vs. Requirements (Checklist)

| # | Requirement | Current State | Gap |
|---|-------------|--------------|-----|
| 1 | Guest checkout directory sync: capture and persist first_name, last_name, email, phone_number | Captured on appointment; clients sync best-effort after create | Make directory sync mandatory (fail booking if sync fails); validate required + email/phone format; match by email and/or phone, update existing instead of duplicate |
| 2 | Health & Skin Disclosure: required; list applicable or “Not applicable”; sync to appointment; full answers not just boolean | Required in UI; booleans + optional additionalNotes stored on appointment | Add per-item detail/“Not applicable” support (schema + UI); keep booleans for backwards compat; require each item answered (applicable or N/A) |
| 3 | Required Acknowledgements: required; sync to appointments with set of acknowledgements and timestamps/version | Required in UI; four booleans on appointment | Add acknowledgedAt (and optional version) to appointment snapshot |
| 4 | Cancellation/no-show policy: required; sync to appointments; store checked, timestamp, policy version or hash | Required in UI; boolean only on appointment | Add cancellationPolicySnapshot: { acknowledged, acknowledgedAt, policyVersion or policyTextHash } |
| 5 | Backwards compatibility: no breaking changes; additive migrations; existing records still work | N/A | All new fields nullable/defaulted; existing appointments without new fields must still display and function |
| 6 | Account creation → full history visible; link guest data via email/phone; avoid incorrect merges | History by email only; no userId; same-email guest bookings already show after signup | Add optional userId to appointments/clients; on signup (or link action), set userId; client appointments: query by uid if present else email; document strong match rules |
| 7 | Admin: Quick actions — preview appointment (forms/disclosures/acknowledgements), print PDF | No appointment PDF | Add “Preview / Print PDF” for selected appointment in admin appointments (e.g. in detail dialog or list actions); PDF content as specified |

---

## C. Risks and Edge Cases

| Risk | Mitigation |
|------|------------|
| Directory sync fails (network, rules) and we now fail booking | Retry once; clear error message; log sync failures. Ensure Firestore rules allow create/update clients (currently admin-only—guests cannot write clients; sync runs server-side or must be done in a context that can write clients). **Critical:** Today guests cannot write to `clients`; only admin can. So directory sync from client/guest booking runs in the **same** Firestore context as the booking (client app). Check rules: `allow write: if isAdmin()` — so **guest cannot create/update clients**. Directory sync in createAppointment is done from the **client** (guest) app, so it will **always fail** for guests. Fix: either (a) allow create/update clients when request is from appointment create (not possible in rules by “who created appointment”), or (b) run client sync in Cloud Function triggered by appointment create (then sync is reliable and server-side), or (c) allow authenticated-or-unauthenticated write to clients for a limited structure (e.g. create/update own by email). **Conclusion:** Current “sync” from guest booking likely fails silently due to rules (clients write is admin-only). Need to fix rules or move sync to Cloud Function. |
| Two guests same email race → duplicate client docs | Use transaction or “getOrCreate” by email+phone; prefer single query by email, then create if not exists (Firestore doesn’t have unique constraint; duplicate clients possible). Idempotent update by email minimizes duplicates; add phone match for linking. |
| Health disclosure “full answers”: migration of existing data | Add new optional fields (e.g. detail strings); existing records remain valid with booleans only. UI: require each item either checked or “Not applicable” (or detail). |
| Old appointments without cancellationPolicySnapshot | Backwards compat: treat missing as cancellationPolicyAcknowledged == true if boolean true, else false; no timestamp. Display “Legacy” or “—”. |
| Account linking: wrong person gets linked | Match rules: require exact email match; optionally require phone match for linking (or email OR phone with caution). Document: link only when email matches; if phone provided, can require phone match for extra safety. |
| PDF generation: missing or null fields on old appointments | Null-safe PDF; show “—”“N/A” for missing disclosure/acknowledgement/cancellation snapshot. |

---

## D. Backwards Compatibility Summary

- **Appointment:** Add optional fields only: health disclosure details (optional map/strings), requiredAcknowledgmentsTimestamp (optional), cancellationPolicySnapshot (optional). Existing documents without these remain valid; readers must handle null/absent.
- **Client:** Add optional `userId`. Existing clients without userId remain valid; “My Appointments” continues to use email when userId is null.
- **Firestore rules:** If we allow non-admin write to clients for sync, restrict to create/update only for the document that matches the appointment’s email (e.g. allow create if no existing client with that email; allow update if resource.data.email == incoming email). Or keep admin-only and implement sync in Cloud Function on appointment create.
- **API:** No removal or renaming of existing fields; no change to existing query patterns except additive (e.g. optional filter by userId).

---

## E. Assumptions

1. **Directory sync from client:** Firestore rules currently allow only admin to write clients. The audit assumes we will either (1) add a rule that allows create/update of a client document when the request comes from an unauthenticated or authenticated user and the document’s email matches a single canonical rule (e.g. create with email in request), or (2) implement directory sync in a Cloud Function (onCreate appointment) so sync is server-side and reliable. Implementation plan will choose one and document.
2. **Health “full answers”:** “List applicable items or explicitly enter ‘Not applicable’” is implemented as: each disclosure item has either a boolean true + optional detail text, or boolean false + optional “Not applicable” (or equivalent) so that every item is explicitly answered.
3. **Policy version/hash:** Cancellation policy text is in TermsAndConditions; we can store a policy version string (e.g. "1.0") or a hash of the policy text at submission time; version is optional and can be added later.
4. **Account linking:** “Full history” is achieved by (a) continuing to show appointments by clientEmail for signed-in user, and (b) optionally setting userId on those appointments and on the client record at signup so future queries can use userId; backwards compat by still supporting email-based fetch.

---

## F. Firestore Rules Note (Critical)

Current snippet:

```text
match /clients/{clientId} {
  allow read: if isAdmin() || (isAuthenticated() && resource.data.email == request.auth.token.email);
  allow write: if isAdmin();
}
```

So **only admin** can create/update clients. Guest booking runs in the **client** (unauthenticated or authenticated as client) context; therefore **`_syncClientFromAppointment` in FirestoreService.createAppointment will fail with permission denied** when the booker is a guest (or any non-admin). The catch block in createAppointment logs the error and does not rethrow to the caller, so the booking **succeeds** but the client record is **not** created/updated. This explains “best-effort” behavior and confirms that **reliable guest directory sync requires a rules change or server-side sync (e.g. Cloud Function)**.

---

*End of audit. See IMPLEMENTATION_PLAN.md for step-by-step changes and schema.*
