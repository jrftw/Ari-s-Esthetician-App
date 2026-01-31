# Ari Esthetician App — Implementation Plan

**Author:** Kevin Doyle Jr. / Infinitum Imagery LLC  
**Date:** January 31, 2026  
**Scope:** Guest directory sync, Health & Skin Disclosure (full answers), Required Acknowledgements + Cancellation policy (timestamps/version), Account linking, Admin appointment PDF. All changes additive and backwards compatible.

---

## 1. Strategy Summary

- **Directory sync:** Implement server-side via Cloud Function `onAppointmentCreated` so guest (unauthenticated) booking still results in a client record. No client-side write to `clients` by guests; rules stay admin-only. App continues to create appointment only; sync is reliable and idempotent in the function.
- **Validation:** Keep and enforce existing validators (required first/last/email/phone, email format, phone length) before submit; add optional server-side validation in Cloud Function for appointment data.
- **Health disclosure:** Extend schema with optional per-item “detail” or “notApplicable” text; keep booleans. Require in UI that each item is either “applicable” (with optional details) or “Not applicable.”
- **Acknowledgements / Cancellation:** Add optional `requiredAcknowledgmentsAcceptedAt` (timestamp) and `cancellationPolicySnapshot` (object: acknowledged, acknowledgedAt, policyVersion or policyTextHash) on appointment. Backwards compat: treat missing as legacy.
- **Account linking:** Add optional `userId` to appointments and clients. On signup (and optional “Link my bookings” action), set `userId` on client doc and on all appointments matching email (and optionally phone). Client “My Appointments” continues to use email-based query; optionally also include appointments where `userId == currentUser.uid` for consistency.
- **Admin PDF:** Add “Preview / Print PDF” for a single appointment in admin appointments (detail dialog or list item actions); PDF includes client, appointment, full disclosure, acknowledgements, cancellation snapshot, timestamps.

---

## 2. DB Schema / Migration (Additive Only)

### 2.1 Appointments

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| (existing) | — | — | No removals. |
| `userId` | string | no | Optional. Set when user signs up or links; used for “My Appointments” by uid. |
| `healthDisclosureDetails` | map | no | Optional. e.g. `{ "skinConditions": "acne", "allergies": "Not applicable" }`. Keys match HealthDisclosure items; values are free text or "Not applicable". |
| `requiredAcknowledgmentsAcceptedAt` | timestamp | no | When the four acknowledgements were accepted (UTC). |
| `cancellationPolicySnapshot` | map | no | `{ acknowledged: bool, acknowledgedAt: timestamp, policyVersion?: string, policyTextHash?: string }`. |

Existing documents without these fields remain valid; readers use null-safe defaults.

### 2.2 Clients

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| (existing) | — | — | No removals. |
| `userId` | string | no | Optional. Set when user signs up or links. |

### 2.3 Firestore Indexes

- Optional: composite index `appointments` (`userId`, `startTime` DESC) for “My Appointments” by uid when used. Can add later if we query by userId.

---

## 3. API / Service Changes

### 3.1 FirestoreService (Dart)

- **createAppointment:** Remove call to `_syncClientFromAppointment` (sync moved to Cloud Function). No other signature change.
- **New (optional):** `syncClientFromAppointment` public method for admin-only or callable use; or leave sync entirely to Cloud Function.
- **getAppointmentsByClientEmail:** Unchanged (still primary for “My Appointments”).
- **Optional:** `getAppointmentsByUserId(String uid)` for future use; or merge in client screen: appointments where `userId == uid` OR `clientEmail == user.email` for backwards compat.

### 3.2 Cloud Functions

- **onAppointmentCreated:** New Firestore trigger `appointments/{id}` onCreate. Read appointment doc; get clientFirstName, clientLastName, clientEmail, clientPhone; getOrCreate client by email (query clients where email == clientEmail; if found update, else add). Idempotent: update fills empty name/phone, increments totalAppointments. Use Admin SDK (no security rules). Log sync failures; optionally retry once.

### 3.3 AuthService / Signup

- After creating user and client record (or finding existing client by email), **link appointments and client to user:**
  - Find all appointments where `clientEmail == user.email` (and optionally `clientPhone == user.phone` if we have it); update each with `userId = user.uid`.
  - Update client doc (by email) with `userId = user.uid`.
- Strong match: require email match; optional phone match for extra safety (document in code).

### 3.4 Client Appointments Screen

- Keep loading by `getAppointmentsByClientEmailStream(_clientEmail!)`. No change required for history to show (same email = same appointments). Optional: also listen to appointments where `userId == currentUser.uid` and merge; not strictly required for “full history” if email is same.

---

## 4. Step-by-Step Implementation Order

### Phase 1: Schema and Models (non-breaking)

1. **Appointment model (Dart)**  
   Add optional: `userId`, `healthDisclosureDetails` (Map<String, String>?), `requiredAcknowledgmentsAcceptedAt` (DateTime?), `cancellationPolicySnapshot` (CancellationPolicySnapshot?).  
   Add class `CancellationPolicySnapshot`: acknowledged, acknowledgedAt, policyVersion?, policyTextHash?.  
   Regenerate `.g.dart`.  
   Backwards compat: fromJson treats missing fields as null.

2. **HealthDisclosure model**  
   Add optional per-item text fields (e.g. skinConditionsDetails, allergiesDetails, …) or a single map `details`; keep existing booleans.  
   Requirement “full answers” can be satisfied by: booleans + optional detail strings; UI requires each item either “yes” (with optional text) or “No / Not applicable” (stored as text).  
   Update HealthDisclosure in appointment_model.dart and generate.

3. **Client model**  
   Add optional `userId`.  
   Regenerate `.g.dart`.

### Phase 2: Directory Sync (reliable)

4. **Cloud Function: onAppointmentCreated**  
   In `functions/index.js`, add `onDocumentCreated('appointments/{id}', ...)`.  
   In handler: get appointment data; extract clientFirstName, clientLastName, clientEmail, clientPhone; query clients where email == clientEmail limit 1; if exists update (empty name/phone, totalAppointments+1), else create new client with those fields.  
   Use Firestore Admin; log errors; no throw (so appointment create is not rolled back).

5. **FirestoreService.createAppointment**  
   Remove the try/catch block that calls `_syncClientFromAppointment` (so we don’t double-sync or fail for guests).  
   Optionally keep a comment that sync is done by Cloud Function.

6. **Validation**  
   Ensure client_booking_screen validators for first name, last name, email format, phone length are enforced before submit (already in place). No API change.

### Phase 3: Health Disclosure (required + full answers)

7. **Health disclosure schema (appointment)**  
   Already added optional details in step 2; ensure appointment stores full snapshot including detail strings at submission time.

8. **Client booking screen – Health & Skin Disclosure**  
   For each disclosure item, require either “Yes” (checkbox) with optional detail text, or “No / Not applicable” (e.g. checkbox unchecked + explicit “Not applicable” or short text).  
   Validate before “Next”/submit: all items answered.  
   Build HealthDisclosure + optional healthDisclosureDetails map when submitting; pass to AppointmentModel.create.

### Phase 4: Acknowledgements and Cancellation (timestamps + snapshot)

9. **Required acknowledgements**  
   When building appointment in _submitBooking, set `requiredAcknowledgmentsAcceptedAt: DateTime.now().toUtc()`.  
   Add field to AppointmentModel and toFirestore/fromJson.

10. **Cancellation policy snapshot**  
    Add CancellationPolicySnapshot: acknowledged (true), acknowledgedAt (now), policyVersion (e.g. "1.0" from constants) or hash of TermsAndConditions cancellation section.  
    Store on appointment; use in PDF and admin detail.

### Phase 5: Account Linking

11. **AuthService – after signup**  
    When role is client: find client doc by email; set userId on that doc.  
    Query appointments where clientEmail == email; batch update each with userId = uid.  
    Use strong match: email required; optional phone match.  
    Log linking actions and failures.

12. **Client appointments screen**  
    Keep current email-based stream. Optional: add query by userId and merge; document that history is by email + linked userId.

### Phase 6: Admin PDF

13. **Admin appointments – Quick actions**  
    In appointment detail dialog (or list item), add “Preview / Print PDF”.  
    Build PDF with: client (first, last, email, phone), appointment (date, time, service, provider/location if available), full health disclosure (booleans + detail text), required acknowledgements + acceptedAt, cancellation policy snapshot + timestamp, terms acceptance metadata (timestamp).  
    Use `pdf` and `printing` packages; show preview then print/save.  
    Handle null/missing fields for old appointments (show “—”“N/A”).

### Phase 7: Tests and Logging

14. **Unit tests**  
    Validation (email, phone, name length).  
    Mapping: HealthDisclosure + details to/from JSON; CancellationPolicySnapshot to/from JSON.  
    Appointment create payload includes new fields.

15. **Integration / linking tests**  
    Guest books → appointment created → Cloud Function runs → client exists (or mock).  
    Signup with email that has guest appointments → appointments and client get userId.

16. **PDF test**  
    Snapshot or golden test: build PDF for a fixture appointment; assert key sections present.

17. **Logging**  
    FirestoreService: log when createAppointment is called (no sync).  
    Cloud Function: log sync success/failure.  
    AuthService: log account linking (count updated, failures).

---

## 5. Compatibility Notes

- **Existing appointments:** No new required fields; detail dialog and PDF use null-safe display for healthDisclosureDetails, requiredAcknowledgmentsAcceptedAt, cancellationPolicySnapshot, userId.
- **Existing clients:** userId null; linking fills it on signup.
- **Firestore rules:** No change to clients (admin-only write); appointments remain create by anyone, read by anyone, update/delete admin. Cloud Function uses Admin SDK.
- **Client app:** No breaking change to existing booking or “My Appointments” flow; only additive fields and one removal of client sync from createAppointment.

---

## 6. Assumptions

- Cloud Function runs in same project as Firestore; Admin SDK has write access to `clients`.
- Policy version can be a constant string (e.g. "1.0") in app constants; policyTextHash can be added later if needed.
- “Provider/location” in PDF can come from business_settings or be omitted if not present.
- Account linking is done at signup only (no separate “Link my bookings” screen in this phase); can be extended later.

---

*End of implementation plan. Proceed with Phase 1–7 in order.*
