# Ari Esthetician App — Acceptance Checklist

**Author:** Kevin Doyle Jr. / Infinitum Imagery LLC  
**Date:** January 31, 2026  
**Purpose:** Pass/fail items matching the mandatory requirements for guest directory sync, disclosures, acknowledgements, cancellation policy, account linking, and admin PDF.

---

## 1. Guest Checkout Directory Sync

| # | Item | Pass / Fail |
|---|------|-------------|
| 1.1 | Guest can complete booking (service → date/time → client info → disclosures → acknowledgements → cancellation → payment if enabled). | ☐ |
| 1.2 | First name, last name, email, phone number are captured and validated (required, email format, phone length). | ☐ |
| 1.3 | Client record is created or updated in `clients` collection (directory) for every booking (guest or logged-in). | ☐ |
| 1.4 | Directory sync is reliable: Cloud Function `onAppointmentCreated` runs on appointment create and syncs client by email (create or update). | ☐ |
| 1.5 | Match by email; no duplicate client docs for same email (idempotent update). | ☐ |

---

## 2. Health & Skin Disclosure

| # | Item | Pass / Fail |
|---|------|-------------|
| 2.1 | Entire "Health & Skin Disclosure" section is required before proceeding. | ☐ |
| 2.2 | Each item is either "applicable" (Yes) or "Not applicable"; full answers stored (e.g. healthDisclosureDetails map on appointment). | ☐ |
| 2.3 | Disclosure snapshot is stored on the appointment at submission time (healthDisclosure + healthDisclosureDetails). | ☐ |
| 2.4 | Schema supports full answers (map of item → text), not only booleans. | ☐ |

---

## 3. Required Acknowledgements

| # | Item | Pass / Fail |
|---|------|-------------|
| 3.1 | "Required Acknowledgements" section is required; all four must be accepted. | ☐ |
| 3.2 | Acknowledgements are stored on the appointment (requiredAcknowledgments + requiredAcknowledgmentsAcceptedAt). | ☐ |
| 3.3 | Timestamp of acceptance is stored (requiredAcknowledgmentsAcceptedAt). | ☐ |

---

## 4. Cancellation / No-Show Policy

| # | Item | Pass / Fail |
|---|------|-------------|
| 4.1 | User must check "I understand and agree to the cancellation and no-show policy" to proceed. | ☐ |
| 4.2 | Cancellation policy is synced to appointment (cancellationPolicyAcknowledged + cancellationPolicySnapshot). | ☐ |
| 4.3 | Snapshot includes: acknowledged boolean, timestamp (acknowledgedAt), policy version or hash (policyVersion). | ☐ |

---

## 5. Backwards Compatibility / Non-Breaking

| # | Item | Pass / Fail |
|---|------|-------------|
| 5.1 | Existing appointment records without new fields (userId, healthDisclosureDetails, requiredAcknowledgmentsAcceptedAt, cancellationPolicySnapshot) still load and display. | ☐ |
| 5.2 | Existing clients without userId still work. | ☐ |
| 5.3 | No breaking API or Firestore rule changes for existing read/write patterns; new rules are additive (e.g. user can update own client/appointments for linking). | ☐ |

---

## 6. Account Creation → Full History Visible

| # | Item | Pass / Fail |
|---|------|-------------|
| 6.1 | After signup, "My Appointments" shows all appointments for that email (including guest bookings with same email). | ☐ |
| 6.2 | Account linking: on signup, userId is set on client doc and on all appointments where clientEmail matches. | ☐ |
| 6.3 | Strong match: linking uses email; no incorrect merges. | ☐ |
| 6.4 | Full history includes every appointment, form payload, disclosures, acknowledgements, policy agreement for those appointments. | ☐ |

---

## 7. Admin: Quick Actions + Preview/Print PDF

| # | Item | Pass / Fail |
|---|------|-------------|
| 7.1 | In admin appointment detail dialog, "Preview / Print PDF" (or equivalent) is available. | ☐ |
| 7.2 | PDF includes: client identity (first, last, email, phone). | ☐ |
| 7.3 | PDF includes: appointment details (date/time, service, status). | ☐ |
| 7.4 | PDF includes: full disclosure answers (health disclosure + details). | ☐ |
| 7.5 | PDF includes: acknowledgements and policy agreement (with timestamps where available). | ☐ |
| 7.6 | PDF includes: submission timestamps (created, updated). | ☐ |
| 7.7 | Existing admin views (list, calendar, detail, create/edit) are unchanged and functional. | ☐ |

---

## 8. Validation & Logging

| # | Item | Pass / Fail |
|---|------|-------------|
| 8.1 | Required client fields validated (first, last, email, phone) with clear error messages. | ☐ |
| 8.2 | Email format and phone format validated (existing patterns). | ☐ |
| 8.3 | Sync failures (Cloud Function) are logged. | ☐ |
| 8.4 | Account linking actions (and failures) are logged. | ☐ |

---

*Use this checklist to verify each requirement after deployment and manual/automated testing.*
