# Ari Esthetician App — Full App Audit

**Audit Date:** January 31, 2026  
**Author:** Kevin Doyle Jr. / Infinitum Imagery LLC  
**Scope:** Entire app — what is broken, what is not working, and what still needs to be finished.

---

## Executive Summary

The app is **largely functional**: guest booking, client directory sync (via Cloud Function), account linking, admin appointment PDF, and compliance fields (health disclosure details, acknowledgement timestamps, cancellation policy snapshot) are implemented. **Broken or inconsistent behavior** exists in two areas: (1) **admin notifications for guest bookings** fail silently due to Firestore rules, and (2) **router code** uses a protected API incorrectly and has minor dead code. **Documentation** (AUDIT_REPORT.md) is outdated regarding directory sync. Several **analyzer/lint issues** (style and deprecated APIs) should be cleaned up for production.

---

## 1. What Is Broken or Not Working

### 1.1 Admin Notifications for Guest Bookings (Broken)

**Behavior:** When a **guest** (unauthenticated user) completes a booking, the app calls `FirestoreService.createAppointment()`, which:

1. Writes the appointment to Firestore ✅ (rules allow public create on `appointments`)
2. Calls `_notificationService.createAppointmentCreatedNotification()` to create an admin notification

**Problem:** Firestore rules for `notifications` are:

```text
allow create: if isAuthenticated();
```

Guests are **not** authenticated, so the notification **create** fails with permission denied. The notification service catches the error and does not rethrow (so the booking still succeeds), but **no notification document is created**. Admins do **not** see “appointment created” in the admin notifications list for guest bookings.

**Where:**  
- `lib/services/firestore_service.dart` — `createAppointment()` calls `_notificationService.createAppointmentCreatedNotification()`  
- `lib/services/notification_service.dart` — writes to `notifications` collection  
- `firestore.rules` — `match /notifications/{notificationId}` → `allow create: if isAuthenticated();`

**Fix options:**

- **Option A (recommended):** Create the “appointment created” notification inside the Cloud Function `onAppointmentCreated` in `functions/index.js`. The function already runs on every new appointment; add a write to the `notifications` collection using the Admin SDK (no security rules). Then remove or keep the client-side call (if kept, it will still fail for guests but at least work for logged-in clients; optional).
- **Option B:** Allow unauthenticated create on `notifications` with very strict validation (e.g. only allow a single document shape that matches “appointment created” and no user-controlled fields). Higher risk and more complex to secure.

---

### 1.2 App Router — Invalid Use of Protected Member (Broken / Risky)

**Behavior:** In `lib/core/routing/app_router.dart`, the redirect handler `_handleRedirect` calls:

- `_authStateNotifier.notifyListeners()` (e.g. around lines 315 and 323)

`notifyListeners()` is a **protected** method on `ChangeNotifier`. It is intended to be called only from **within** the subclass that extends `ChangeNotifier` (here, `_AuthStateNotifier`). Calling it from **outside** that class (from `AppRouter`) is invalid and triggers analyzer warnings:

- `invalid_use_of_protected_member`
- `invalid_use_of_visible_for_testing_member`

**Risk:** Depending on Flutter/Dart version, this can lead to unexpected behavior or future breakage. It also violates the intended API of `ChangeNotifier`.

**Where:** `lib/core/routing/app_router.dart` — inside `_handleRedirect`, after resolving the user.

**Fix:** Add a public method on `_AuthStateNotifier`, e.g. `void refresh() { notifyListeners(); }`, and call `_authStateNotifier.refresh()` from `AppRouter._handleRedirect` instead of `_authStateNotifier.notifyListeners()`.

---

### 1.3 App Router — Unnecessary Null Check and Unused Field

**Behavior:**

- Around line 387 the code checks `finalUser == null` in a context where the analyzer considers that the operand cannot be null (e.g. after an earlier assignment), so the condition is always true and the check is unnecessary.
- The field `_preferencesService` in `AppRouter` is never used (only `PreferencesService.instance` is used elsewhere), triggering an unused_field warning.

**Where:** `lib/core/routing/app_router.dart`.

**Fix:** Remove the redundant null check (or restructure if the intent was different). Remove the unused `_preferencesService` field or use it where appropriate.

---

## 2. What Needs to Be Finished or Improved

### 2.1 Documentation — AUDIT_REPORT.md Outdated

**Current state:** AUDIT_REPORT.md describes directory sync as **client-side** (`_syncClientFromAppointment` in `FirestoreService.createAppointment`) and states that guest booking fails to write to `clients` because of Firestore rules (admin-only write).

**Actual state:** Directory sync is implemented **server-side** in the Cloud Function `onAppointmentCreated` in `functions/index.js`. The client no longer calls `_syncClientFromAppointment` from `createAppointment`; the comment in `firestore_service.dart` correctly says the Cloud Function syncs name, email, and phone to `clients`. So guest directory sync **does work** (via the function).

**Action:** Update AUDIT_REPORT.md (and any other docs that still describe client-side-only sync) to reflect that directory sync is handled by `onAppointmentCreated` and that guest bookings **do** result in client records when the function runs.

---

### 2.2 Optional: “My Appointments” by userId

**Current state:** Client appointments are loaded by **email** only: `getAppointmentsByClientEmailStream(_clientEmail!)`. Account linking sets `userId` on the client doc and on appointments when the user signs up; history is still fetched by email, so “My Appointments” already shows all appointments for that email (including past guest bookings with the same email).

**Possible improvement:** For consistency and future-proofing, “My Appointments” could also (or primarily) query by `userId` when present, e.g. appointments where `userId == currentUser.uid`, with a fallback to email for backwards compatibility. Not required for current acceptance criteria but mentioned in IMPLEMENTATION_PLAN.md.

---

### 2.3 Stripe / Email Configuration

**Current state:**  
- Stripe: Cloud Functions use `functions.config().stripe?.secret_key` or `STRIPE_SECRET_KEY`. If not set, payment-related functions will throw.  
- Email: Confirmation and reminder emails use SMTP via `functions.config().smtp` (see EMAIL_SETUP.md). If SMTP is not configured, sending fails and is logged; booking still succeeds.

**Action:** Ensure production has Stripe and SMTP configured; document in deployment/setup docs.

---

## 3. What Is Working (Verified)

- **Guest booking flow:** Welcome → Account Choice → Continue as Guest → Booking. Appointment is created; overlap and time-off checks work.
- **Client directory sync:** Cloud Function `onAppointmentCreated` syncs client name, email, phone to `clients` (create or update by email). Works for guest and logged-in bookings.
- **Compliance data:** Health disclosure details, required acknowledgements timestamp, and cancellation policy snapshot are on the appointment model and are set in `client_booking_screen.dart` when submitting.
- **Account linking:** On signup, `linkClientAndAppointmentsToUser` sets `userId` on the client doc and on all appointments matching the user’s email. “My Appointments” shows full history by email.
- **Admin appointment PDF:** “Preview / Print PDF” in the admin appointment detail dialog; PDF includes client, appointment details, disclosures, acknowledgements, policy, timestamps. Web and mobile paths exist.
- **Confirmation email:** Sent after booking via `EmailService.sendConfirmationEmail` (Cloud Function `sendAppointmentConfirmationEmail`). Failures are caught; booking still succeeds.
- **Firestore indexes:** Composite index for `appointments` on `clientEmail` + `startTime` (desc) is present in `firestore.indexes.json` for client appointments stream.
- **Auth and routing:** Login, signup, role-based redirect (admin vs client), and public routes (booking, confirmation, appointments, settings) behave as intended. Splash waits for auth restoration then navigates.

---

## 4. Analyzer / Lint Issues (Non-Blocking but Recommended)

Running `flutter analyze lib` reports:

- **Style:** Many `prefer_single_quotes` (e.g. in `app_constants.dart`, `app_version.dart`).  
- **Unused:** `unused_import` in `app_typography.dart` (e.g. `app_colors.dart`); `unused_field` in `app_router.dart` (`_preferencesService`).  
- **Deprecated:** `deprecated_member_use` (e.g. `printTime` in `app_logger.dart`; `background` in `app_theme.dart`).  
- **Other:** `prefer_const_declarations`, `prefer_const_constructors`, `constant_identifier_names` (e.g. `ENABLE_DEBUG_LOGGING`), `curly_braces_in_flow_control_structures` in a few files.

None of these prevent the app from running but should be addressed for consistency and to avoid future deprecation breakage.

---

## 5. Summary Checklist

| Item | Status | Action |
|------|--------|--------|
| Guest directory sync | ✅ Working | Cloud Function `onAppointmentCreated` — none |
| Admin notification for guest bookings | ❌ Broken | Create notification in Cloud Function or relax rules (see 1.1) |
| Router: notifyListeners from AppRouter | ❌ Invalid API use | Expose `refresh()` on notifier and call that (see 1.2) |
| Router: unnecessary null check / unused field | ⚠️ Lint | Remove redundant check; remove or use `_preferencesService` (see 1.3) |
| AUDIT_REPORT.md | ⚠️ Outdated | Update to reflect server-side directory sync (see 2.1) |
| Compliance fields (health details, acknowledgement time, cancellation snapshot) | ✅ Implemented | None |
| Admin appointment PDF | ✅ Implemented | None |
| Account linking (userId on signup) | ✅ Implemented | None |
| Analyzer / lint | ⚠️ Info/warnings | Fix style, unused imports/fields, deprecations (see §4) |

---

## 6. Suggested Fix Order

1. **Router:** Add `refresh()` to `_AuthStateNotifier` and replace `notifyListeners()` calls in `AppRouter`; remove unused field and redundant null check.
2. **Notifications for guests:** Implement “appointment created” notification in `onAppointmentCreated` (functions/index.js) so admins see all new bookings; keep or remove client-side notification call as desired.
3. **Docs:** Update AUDIT_REPORT.md (and related docs) for directory sync.
4. **Lint:** Address analyzer suggestions (quotes, const, unused imports/fields, deprecated APIs) in batches by file or by rule.

---

*End of full app audit. For requirement-level details see AUDIT_REPORT.md and ACCEPTANCE_CHECKLIST.md; for implementation steps see IMPLEMENTATION_PLAN.md.*
