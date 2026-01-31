# Ari Esthetician App — Full Application Audit (Current State)

**Audit Date:** January 30, 2026  
**Last Updated:** January 30, 2026  
**Author:** Kevin Doyle Jr. / Infinitum Imagery LLC  
**Scope:** Entire Flutter/Firebase codebase, Firestore rules, indexes, Firebase config, and analyzer.

---

## Executive Summary

The app is **structurally sound** and **fully functional** for core flows. Previous critical and minor issues have been fixed: guest booking (time_off rules), analyzer warnings (firebase_config, duplicate import), Firestore index file (composite indexes added, single-field clients/email removed to avoid 400), and Firebase CLI setup (firebase.json + .firebaserc). This audit adds: **feature inventory**, **risk list**, **Firebase free-tier risk points**, **performance hotspots**, and **fix plan** for correctness/stability, performance, and free-tier compliance. Several **stream subscription leaks** and one **router/auth notifier leak** were identified; fixes are minimal and localized.

---

## A. Feature Inventory & Mapping

### A.1 Features / Modules / Screens

| Area | Screens / Modules | Purpose |
|------|------------------|---------|
| **Bootstrap** | main.dart, firebase_config.dart | Entry, Firebase init, version check, theme prefs, router. |
| **Routing** | app_router.dart | GoRouter with ShellRoute (AuraScreenWrapper). Routes: splash, welcome, account-choice, login, signup, booking, confirmation, appointments, settings; admin: dashboard, services, appointments, clients, settings, categories, earnings, notifications, software-enhancements, time-off. |
| **Auth** | login_screen, signup_screen | Login/signup, remember me, keep signed in, saved email/password, admin vs client redirect. |
| **Welcome / Onboarding** | splash_screen, welcome_screen, account_choice_screen, update_required_screen | Splash (2s + auth), welcome, account choice (login/signup/guest), update gate. |
| **Client** | client_booking_screen, client_confirmation_screen, client_appointments_screen | Booking (service → date/time → client info → payment → confirmation), confirmation, my appointments (tabs: upcoming / past). |
| **Admin** | admin_dashboard_screen, admin_services_screen, admin_appointments_screen, admin_clients_screen, admin_settings_screen, admin_category_management_screen, admin_earnings_screen, admin_notifications_screen, admin_software_enhancements_screen, admin_time_off_screen | Dashboard (unread count), services/categories CRUD, appointments (list/calendar, filters, create/edit), clients CRUD/search, business settings, earnings, notifications (read/archive), software enhancements (superAdmin), time-off CRUD. |
| **Settings** | settings_screen | Theme (light only), aura (on/off, intensity, color), changelog, logout. |
| **Services** | auth_service, firestore_service, preferences_service, version_check_service, notification_service, view_mode_service, payment_service, email_service, device_metadata_service, app_diagnostics_service | Auth, Firestore CRUD + streams, SharedPreferences (theme/aura/login), version check (Firestore doc), notifications, view mode (admin-as-client), Stripe, email, diagnostics. |

### A.2 State Management, Routing, Persistence, Firebase

- **State:** Widget-local `setState` + services (AuthService, FirestoreService, PreferencesService, ViewModeService). No Provider/Riverpod in use in current flows.
- **Routing:** go_router (GoRouter). Redirect uses `_AuthStateNotifier` (ChangeNotifier) as `refreshListenable`; notifier holds a `StreamSubscription` to `FirebaseAuth.authStateChanges()` and disposes it in `dispose()`. **Issue:** `AppRouter` (and thus `_AuthStateNotifier`) is recreated on every `ArisEstheticianApp.build()`, so previous notifier is never disposed → **auth subscription leak** when app state rebuilds (e.g. version check or prefs).
- **Persistence:** SharedPreferences (theme mode, aura enabled/intensity/color, remember me, keep signed in, saved email/password). Firestore for all business data and app_version.
- **Firebase:** Auth (email/password, persistence LOCAL on web), Firestore (services, appointments, clients, business_settings, serviceCategories, notifications, software_enhancements, time_off, app_version, users). No Cloud Functions invoked from app in audited flow; no Analytics/Crashlytics in use.

### A.3 Key Flows

- **Auth:** Splash → (optional) Welcome / Account choice → Login or Signup → redirect to /admin or /booking by role.
- **Onboarding:** Splash (2s) → auth check → /admin, /booking, or /welcome.
- **Navigation:** ShellRoute wraps all routes with AuraScreenWrapper; theme/aura from PreferencesService.
- **Settings toggles:** Theme (light only), Aura (on/off, intensity, color theme). All persist via PreferencesService and load in SettingsScreen and main app; PreferencesService.notifyListeners() triggers rebuilds.
- **Primary feature actions:** Client booking (multi-step + payment if enabled), admin CRUD (services, categories, appointments, clients, settings, time-off, notifications, software enhancements).
- **Notifications:** In-app only (NotificationService writes to Firestore; admin screens use streams or one-off reads). No FCM push flow audited.
- **Uploads/Downloads:** Business settings logo URL (no direct upload in audited code); no file upload/download flows that would require Blaze.

---

## B. Risk List (What Could Break)

| Risk | Location | Impact | Severity |
|------|----------|--------|----------|
| **Stream subscriptions never cancelled** | settings_screen (authStateChanges), admin_dashboard_screen (unread count stream), admin_appointments_screen (appointments stream), admin_notifications_screen (notifications + unread streams), admin_software_enhancements_screen (enhancements stream) | Memory leak, setState after dispose if stream emits after widget disposed, extra Firestore listeners | High |
| **Auth notifier never disposed** | app_router.dart / main.dart | Each app rebuild creates new AppRouter → new _AuthStateNotifier and new auth subscription; old one never disposed → multiple auth listeners over time | Medium |
| **Unbounded appointments stream** | admin_appointments_screen calls getAppointmentsStream() with no date range | Listener reads all appointments forever → Firestore read cost and free-tier risk | Medium |
| **searchClients fetches all clients** | firestore_service.searchClients() | Calls getAllClients() then filters in memory → heavy read when client list grows | Low–Medium |
| **Redirect calls isAdmin() multiple times** | app_router _handleRedirect | Up to 3x isAdmin() per redirect (logged-in unauth route, admin route, client route) → extra Firestore reads (users doc) | Low |
| **Version check on every cold start** | main.dart | Single read to app_version/latest; acceptable but no caching (e.g. 24h) | Low |
| **getPublicScheduleAppointmentsStream unbounded** | firestore_service | If used without date filter, full collection listener | Low (only if UI uses it unbounded) |

---

## C. Firebase Free-Tier Risk Points (Reads / Writes / Listeners)

| Item | Type | Risk | Note |
|------|------|------|------|
| **getAppointmentsStream()** (no params) | Listener | **High** | Admin appointments screen subscribes with no startDate/endDate → listens to entire appointments collection; every change triggers read. |
| **getAppointmentsByClientEmailStream(email)** | Listener | Medium | Bounded by clientEmail; acceptable if used sparingly. |
| **getPublicScheduleAppointmentsStream()** | Listener | Medium | whereIn status + orderBy startTime; unbounded in time. |
| **getActiveCategoriesStream()** | Listener | Low | Small collection. |
| **getSoftwareEnhancementsStream()** | Listener | Low | Typically small. |
| **getTimeOffStream()** | Listener | Low | Typically small. |
| **getNotificationsStream()** | Listener | Medium | Can grow; admin notifications screen keeps listener open. |
| **getUnreadNotificationsCountStream()** | Listener | Low | Single collection query. |
| **getAllNotifications(includeArchived)** | One-off get() | Medium | Fetches full list; no pagination. |
| **getAllClients()** | One-off get() | Medium | Used by admin clients list and searchClients; no pagination. |
| **getAllAppointments()** | One-off get() | Medium | Used for admin; no pagination. |
| **Version check** | One-off get() | Low | 1 read per app start to app_version/latest. |
| **Auth getUserRole / isAdmin** | One-off get() | Low | 1 read per call to users/{uid}. |
| **Notification creation on appointment events** | Writes | Low | Proportional to appointment actions. |

**Summary:** Biggest free-tier risks are (1) unbounded **getAppointmentsStream()** in admin appointments screen, and (2) **multiple long-lived listeners** (appointments, notifications, enhancements, unread count) that are not cancelled when screens dispose, so they keep consuming reads and connections.

---

## D. Performance Hotspots

| Location | Issue | Impact |
|---------|--------|--------|
| **admin_appointments_screen** | getAppointmentsStream() with no date range + stream.listen not cancelled | Heavy initial + ongoing reads; rebuilds on every appointment change; leak. |
| **admin_notifications_screen** | Two streams (list + unread count), neither cancelled | Rebuilds and listener growth when leaving screen. |
| **admin_dashboard_screen** | getUnreadNotificationsCountStream().listen() not cancelled | Listener leak when leaving dashboard. |
| **admin_software_enhancements_screen** | getSoftwareEnhancementsStream().listen() not cancelled | Listener leak. |
| **settings_screen** | authStateChanges.listen() not cancelled | Auth listener leak. |
| **client_booking_screen** | _loadBusinessSettings().then(...) without unawaited / cancel | Acceptable (mounted checks inside). |
| **app_router redirect** | Multiple await _authService.isAdmin() per redirect | Extra Firestore reads; consider caching role per session. |
| **firestore_service.searchClients** | getAllClients() then in-memory filter | O(n) reads; consider Firestore query + limit for large client lists. |
| **ArisEstheticianApp.build()** | Creates new AppRouter().router on every build | New auth notifier + subscription each time; old notifier never disposed. |

---

## E. Fix Plan (Ordered Steps)

| Step | File(s) | Change | Why safe | How to verify |
|------|---------|--------|----------|----------------|
| 1 | settings_screen.dart | Store StreamSubscription from authStateChanges.listen; cancel in dispose(). | No behavior change; only cancels when widget is disposed. | Open Settings, leave screen; confirm no leak (no setState after dispose). |
| 2 | admin_dashboard_screen.dart | Store StreamSubscription from getUnreadNotificationsCountStream().listen(); cancel in dispose(). | Same. | Enter/leave dashboard repeatedly; no leak. |
| 3 | admin_appointments_screen.dart | (a) Store StreamSubscription from getAppointmentsStream().listen(); cancel in dispose(). (b) Optionally pass date range to getAppointmentsStream() to limit reads (e.g. last 12 months + next 12 months). | (a) Prevents leak. (b) Reduces Firestore reads; backward compatible if service supports optional params. | Leave screen → subscription cancelled; with (b) confirm list still loads for intended range. |
| 4 | admin_notifications_screen.dart | Store both StreamSubscriptions (notifications + unread count); cancel both in dispose(). | No behavior change. | Enter/leave notifications screen; both streams cancelled. |
| 5 | admin_software_enhancements_screen.dart | Store StreamSubscription from getSoftwareEnhancementsStream().listen(); cancel in dispose(). | No behavior change. | Enter/leave screen; subscription cancelled. |
| 6 | app_router.dart / main.dart | Keep single _AuthStateNotifier and GoRouter instance: e.g. create AppRouter once and reuse (e.g. in State or static/singleton), or ensure GoRouter disposes refreshListenable. Minimal fix: make AppRouter a singleton and expose router so not recreated on every build. | Stops creating new auth subscription on every app rebuild. | Rebuild app (e.g. toggle prefs); only one auth listener active; no accumulation. |
| 7 | firestore_service.dart (optional) | Add optional startDate/endDate to getAppointmentsStream() and use in query when provided. | Reduces reads when admin uses date-bounded view. | Admin appointments: pass range; confirm list and stream still work. |
| 8 | (Optional) app_router.dart | Cache isAdmin() result for current user for redirect (e.g. until logout or uid change) to avoid 3x Firestore read per redirect. | Fewer reads; same redirect behavior. | Login as admin/client; redirect unchanged; fewer user doc reads. |

Implementation completed: steps 1–7 (stream subscription fixes in all five screens, single AppRouter + dispose, date-bounded appointments stream). Step 8 (cache isAdmin) deferred.

---

## F. Verification Checklist (Post-Fix)

Use this to verify every feature, setting, button, and toggle after the audit fixes.

### Bootstrap & routing
- [ ] App starts; splash shows then redirects (welcome / booking / admin by auth).
- [ ] Firebase error screen shows if Firebase fails; copy diagnostic works.
- [ ] Version check loading shows then normal app or update required screen.
- [ ] Update required screen shows when Firestore version requires update; app otherwise enters normally.
- [ ] Router: navigate to /welcome, /login, /signup, /booking, /appointments, /settings.
- [ ] Router: logged-in admin → /admin and all admin routes; logged-in client → /booking, /appointments, /settings; non-admin cannot open /admin.
- [ ] Shell: aura/theme changes (Settings) rebuild shell (aura background).

### Auth
- [ ] Login: email/password, remember me, keep signed in; saved email/password prefill and persist.
- [ ] Login: success → redirect admin or client; failure shows error.
- [ ] Signup: create account; client record created when role client.
- [ ] Logout (Settings): clears session; redirect to welcome/login.
- [ ] Session restore: restart app with keep signed in → still logged in.

### Settings (all must persist and load on restart)
- [ ] Theme: light only (dark/auto disabled); setting persists and loads.
- [ ] Aura: on/off toggle persists and loads.
- [ ] Aura intensity: low/medium/high persists and loads.
- [ ] Aura color theme: warm/cool/spa/sunset persists and loads.
- [ ] Changelog: expand/collapse.
- [ ] Copy diagnostic report (when diagnostics have failures).

### Client flows
- [ ] Booking: service selection → date/time → client info → payment (if enabled) → confirmation; guest and logged-in.
- [ ] Booking: categories, search, calendar, time slots, health disclosures, terms, cancellation policy.
- [ ] Confirmation: screen shows for appointment ID; tip/payment if applicable.
- [ ] My Appointments: tabs Upcoming / Past; list loads; add appointment → booking.

### Admin flows
- [ ] Dashboard: loads; unread notifications badge; quick links (services, appointments, clients, settings, etc.).
- [ ] Services: list, create, edit, delete; categories filter if used.
- [ ] Appointments: list and calendar view; filters (status, date range, search); create/edit appointment; status updates; date-bounded stream (no unbounded read).
- [ ] Clients: list, search, create, edit.
- [ ] Business settings: load/save all fields (name, contact, hours, policies, Stripe, etc.).
- [ ] Categories: list, create, edit, soft delete.
- [ ] Earnings: screen loads.
- [ ] Notifications: list, mark read, archive; unread count updates.
- [ ] Software enhancements (superAdmin): list, create, edit, delete.
- [ ] Time-off: list, create, edit, delete.

### Correctness after fixes (no regressions)
- [ ] Leaving Settings → auth subscription cancelled (no leak).
- [ ] Leaving Admin Dashboard → unread count subscription cancelled.
- [ ] Leaving Admin Appointments → appointments subscription cancelled; list still loads for _firstDay–_lastDay.
- [ ] Leaving Admin Notifications → both subscriptions cancelled.
- [ ] Leaving Admin Software Enhancements → enhancements subscription cancelled.
- [ ] App rebuild (e.g. prefs/version) → single router/notifier; dispose on app dispose.

### Manual test steps (if automated tests not run)
1. Open Settings, toggle aura, go back; restart app → aura value persisted.
2. Open Admin Dashboard, then Admin Notifications, then back to Dashboard → no duplicate listeners.
3. Open Admin Appointments → confirm list shows appointments in ±1 year range only.
4. Log in as admin, navigate to all admin screens, then log out → no crashes.

---

## 1. What Is Fixed and Working (Previous Audit)

## 1. What Is Fixed and Working

### 1.1 Core & Bootstrap
- **main.dart** — Entry point, Flutter binding, Firebase init, version check, error/update screens. Graceful fallback if Firebase or router fails.
- **firebase_config.dart** — Initializes Firebase with `DefaultFirebaseOptions.currentPlatform`; safe substring logging for API Key/App ID (no null-aware on non-nullable).
- **firebase_options.dart** — Present in `lib/core/config/`; web config filled; Android/iOS/macOS placeholders (run `flutterfire configure` for native).

### 1.2 Routing & Auth
- **app_router.dart** — GoRouter: splash, welcome, account-choice, login, signup, client (booking, confirmation, appointments), admin (dashboard, services, appointments, clients, settings, categories, earnings, notifications, software enhancements, time-off), settings. Redirect waits for auth restoration; admin vs client enforced.
- **AuthService** — Sign in/up, sign out, role from Firestore `users/{uid}`, `isAdmin`/`isSuperAdmin`, password reset, `waitForAuthStateRestoration`, `restoreSessionIfEnabled`, `checkExistingSession`. Client record created on signup when role is client.
- **LoginScreen** — Form, remember me / keep signed in, preference load/save, admin vs client redirect, error handling, version footer.

### 1.3 Firestore & Business Logic
- **FirestoreService** — Services (active/all, CRUD), appointments (create with overlap check, client sync, notifications), clients (getOrCreate, sync from appointment, stats on status change, recalc, search), business settings, categories (active/all, CRUD, soft delete), software enhancements, time-off (CRUD, range, stream). **isTimeSlotAvailable** uses business hours, overlap check, and time-off; **time_off** is now publicly readable so guest booking works.
- **NotificationService** — Notifications for appointment created/updated/canceled/status-changed.
- **PreferencesService** — Remember me, keep signed in, saved email/password, clear methods. Singleton, SharedPreferences.

### 1.4 Models
- **ClientModel** — `create`, `fromFirestore`, `toFirestore`, `copyWith`; used by auth signup and FirestoreService.
- **AppointmentModel**, **ServiceModel**, **ServiceCategoryModel**, **BusinessSettingsModel**, **TimeOffModel**, **NotificationModel**, **SoftwareEnhancementModel** — Used consistently; `.g.dart` generated.

### 1.5 Client Booking
- **ClientBookingScreen** — Multi-step flow (service → date/time → client info → payment → confirmation). Categories, search, calendar, time slots, client form, health disclosures, terms, Stripe when `_paymentsEnabled`. Admin “view as client” via ViewModeService. Single import of `appointment_model.dart` (duplicate removed).

### 1.6 Version & Update
- **VersionCheckService** — Reads Firestore `app_version/latest`, compares version/build, skips in dev (`AppVersion.isDevelopment`). Fail-open on error/timeout.
- **AppVersion** — `version`, `buildNumber`, `environment`, `versionString`, `compareVersions`, `isDevelopment`.

### 1.7 UI & Theming
- **AppTheme**, **AppColors**, **AppTypography** — Used across screens.
- **SplashScreen** — 2s delay, auth check, redirect to /admin, /booking, or /welcome.
- **WelcomeScreen**, **AccountChoiceScreen**, **UpdateRequiredScreen** — Entry, account choice, and update gate.

### 1.8 Firestore Rules (Current — All Correct)
- **users** — Own read; create own on signup; update own or admin; delete admin only.
- **services, business_settings, app_version, serviceCategories** — Public read; admin write (or superAdmin where intended).
- **appointments** — Create public; read for admin, authenticated, or recent (1h) for confirmation; update/delete admin only.
- **clients** — Read admin or own (by email); write admin only.
- **payments, availability** — Admin only / public read + admin write as defined.
- **notifications** — Admin read; create authenticated (to be tightened later).
- **software_enhancements** — superAdmin only.
- **time_off** — **Public read** (so guests can check availability); create/update/delete admin only.

### 1.9 Firestore Indexes (Current — In File and Deployable)
- **appointments** — (startTime ASC, status ASC), (status ASC, startTime ASC), (clientEmail ASC, startTime DESC).
- **clients** — (lastName ASC, firstName ASC) only. Single-field (email) removed from file to avoid Firestore 400 “single field index controls.”
- **services** — (isActive ASC, displayOrder ASC).
- **serviceCategories** — (isActive DESC, sortOrder ASC, name ASC), (isActive ASC, sortOrder ASC, name ASC).
- **time_off** — (isActive ASC, startTime ASC).

### 1.10 Firebase CLI
- **firebase.json** — firestore (rules + indexes), storage, functions, hosting (build/web).
- **.firebaserc** — default project `ari-s-esthetician-app`. Enables `firebase deploy --only firestore` / `firestore:rules` from project root.

---

## 2. What Was Broken and Is Now Fixed

| Issue | Fix Applied |
|-------|-------------|
| **Guest booking (critical)** — time_off read required auth; guests got permission denied when checking availability | `firestore.rules`: **time_off** set to `allow read: if true;`; write remains admin-only. Rules deployed. |
| **firebase_config.dart** — Unnecessary `?.` on non-nullable apiKey/appId; analyzer warning | Replaced with safe `substring(0, min(10, length))` for API Key and App ID. |
| **client_booking_screen.dart** — Duplicate import of `appointment_model.dart` | Removed duplicate; single import retained. |
| **firestore index deploy** — 400 on clients index (“not necessary, single field index controls”) | Removed single-field **clients (email)** from `firestore.indexes.json`; kept **clients (lastName, firstName)**. |
| **Missing composite indexes** — appointments by clientEmail; serviceCategories; time_off | Added to `firestore.indexes.json`: appointments (clientEmail, startTime DESC), serviceCategories (both variants), time_off (isActive, startTime). |
| **Firebase CLI** — “Not in a Firebase app directory (could not locate firebase.json)” | Created `firebase.json` and `.firebaserc` in project root. |

---

## 3. What Is Still Missing or Optional

### 3.1 Optional Features (Documented, Not Blocking)
- **Forgot Password** — Mentioned in LoginScreen “Suggestions”; no link or handler. Optional.
- **Dark theme** — Commented out in main.dart; not implemented.
- **Custom Sunflower font** — pubspec assets/fonts commented out; not in use.
- **firebase_options for native** — Android/iOS/macOS use placeholders; run `flutterfire configure` when building for those platforms.

### 3.2 Cleanup (Non-Blocking)
- **lib/screens/admin/dart** — Empty file; no purpose. Safe to delete.
- **html_stub.dart** — Used by `admin_services_screen.dart` conditional import for non-web; keep. **dart:html** in `device_metadata_service_web.dart` is deprecated (use package:web / dart:js_interop later); info only.
- **Unused imports** — e.g. device_metadata_service (package_info_plus), email_service (mailer, business_settings_model), payment_service (http, dart:convert, app_constants, business_settings_model). Can be removed for cleaner analyze.
- **Logging style** — AuthService uses `AppLogger().logInfo(...)`; app_router and others use global `logAuth`, `logRouter`, etc. Both work; standardizing is optional.

### 3.3 Analyzer Summary (Current)
- **No fatal/blocking errors.** Build and run are OK.
- **Warnings:** Unused imports (device_metadata_service, email_service, payment_service), unused local variables, one unnecessary non-null assertion (payment_service). Fix when convenient.
- **Info:** Many `prefer_const_*`, `deprecated_member_use` (e.g. `withOpacity` → `.withValues()`), `use_build_context_synchronously`, `avoid_web_libraries_in_flutter` (dart:html). Style and deprecation; not blocking.

### 3.4 Dependencies (Unused in Audited Flow)
- **Provider / Riverpod** — In pubspec; state is widget + services in reviewed flow. Use later or remove to trim deps.

---

## 4. Summary Table (Current State)

| Category | Status |
|----------|--------|
| App bootstrap | OK |
| Firebase init | OK |
| Routing & redirect | OK |
| Auth (login/signup/role) | OK |
| Firestore services | OK |
| Client booking flow | OK |
| Guest booking (time_off) | OK (rules fixed, deployed) |
| Version check | OK |
| Firestore rules | OK (all collections correct) |
| Firestore indexes | OK (composites in file; clients single-field removed) |
| Firebase CLI deploy | OK (firebase.json + .firebaserc) |
| Analyzer | Warnings + info only; no blocking errors |
| Stray file | 1 empty (`lib/screens/admin/dart`) — cleanup only |

---

## 5. Recommended Next Steps (Optional)

1. **Cleanup:** Delete `lib/screens/admin/dart`; remove unused imports in device_metadata_service, email_service, payment_service.
2. **Optional features:** Forgot Password from login; dark theme; native firebase_options via `flutterfire configure` when targeting Android/iOS.
3. **Deprecations:** Plan migration from `withOpacity` to `.withValues()` and from `dart:html` to package:web / dart:js_interop (low priority).
4. **Index deploy:** Run `firebase deploy --only firestore` to push current indexes if not already done; confirm no 400 on clients.

---

## 6. iOS Compliance (January 30, 2026)

A separate **iOS audit** was completed. See **IOS_AUDIT.md** for the full checklist. Summary:

- **iOS platform added** via `flutter create --platforms=ios .` (previously missing).
- **Info.plist** updated with **LSApplicationQueriesSchemes** (required for `url_launcher` on iOS).
- **Podfile** and Xcode set to **iOS 15.0** minimum (required by cloud_firestore 6.x).
- **App constants** `minIOSVersion` set to 15 to match.
- **Before App Store:** Run `flutterfire configure` (add iOS app in Firebase), add `GoogleService-Info.plist`, set signing in Xcode, replace App Store URL placeholder in `update_required_screen.dart`.

---

*End of audit. Application is in a good state for production use of core flows (web); native and polish items are optional. iOS is configured and documented in IOS_AUDIT.md.*
