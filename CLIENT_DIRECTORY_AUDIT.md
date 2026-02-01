# Client Directory Audit

**Purpose:** Confirm that all booking sources add contact info to the client directory, and document guest “create account?” behavior.

**Author:** Kevin Doyle Jr. / Infinitum Imagery LLC  
**Last Modified:** 2026-01-31

---

## 1. Does a guest booking add info to the client directory?

**Yes.** Guest bookings write only to the `appointments` collection (from `FirestoreService.createAppointment`). The Cloud Function **`onAppointmentCreated`** in `functions/index.js` runs on every new appointment document. It calls `ariSyncClientFromAppointmentData`, which:

- Looks up a client in `clients` by `email` (from the appointment).
- If none: **creates** a client with name, email, phone, and stats.
- If one exists: **updates** that client (name/phone if provided, increments `totalAppointments`, sets `lastAppointmentAt`, and can set `userId` if present).

So every guest booking ends up with a corresponding client record (create or update) in the client directory.

---

## 2. Does creating an account add the user to the client directory?

**Yes.** In `lib/services/auth_service.dart`, during **sign-up** (`signUpWithEmailAndPassword`):

- The app checks for an existing client with that email in the `clients` collection.
- If **no** client exists: it **creates** a new client document with that email and the new user’s `uid` (`userId`).
- If a client **already** exists (e.g. from prior guest bookings): it does not create a duplicate; it only runs **account linking**.
- It then calls `FirestoreService.linkClientAndAppointmentsToUser(uid, email)`, which:
  - Sets `userId` on the client document for that email.
  - Sets `userId` on all appointments with that `clientEmail`.

So new accounts either create a new client or link an existing guest client to the account; in both cases the client directory has the user’s info.

---

## 3. Does an admin test booking add the booker to the client directory?

**Yes.** Admin test bookings use the same path as guest bookings: `FirestoreService.createAppointment(appointment)` (e.g. from `admin_appointments_screen.dart`). The appointment is written to `appointments` with whatever client name/email/phone the admin entered. The same Cloud Function **`onAppointmentCreated`** runs and syncs that data into the `clients` collection (create or update by email). So admin test bookings are also reflected in the client directory.

---

## 4. Summary: “All bookings add to the client directory”

| Source              | Adds to client directory? | How                                                                 |
|---------------------|---------------------------|---------------------------------------------------------------------|
| Guest booking       | Yes                       | Cloud Function `onAppointmentCreated` syncs from appointment data  |
| User creates account| Yes                       | AuthService creates client (or uses existing) and links by email    |
| Admin test booking  | Yes                       | Same Cloud Function on new appointment                             |

All bookings are represented in the client directory either via the Firestore trigger or via sign-up + linking.

---

## 5. Guest books again (no account): “Create account?” prompt

**Behavior (after implementation):**

- When a **guest** (not signed in) completes a booking, the app checks whether a client with that booking email **already exists** and has **no** `userId` (i.e. guest-only, no account).
- If so, after a successful booking the app shows a one-time prompt:
  - **Message:** Ask if they want to create an account to combine their booking history and manage appointments.
  - **Create account:** Navigate to sign-up with email pre-filled; after sign-up, existing linking logic attaches the client and all appointments to the new account.
  - **Decline (e.g. “Not now”):** No account created; user continues to the confirmation screen. No data is merged; they remain a guest.

This applies only to guests; signed-in users are not shown the prompt. The prompt is optional; the user can decline and continue as a guest.

---

## 6. Implementation notes

- **Client lookup:** `FirestoreService.getClientByEmail(email)` returns the client for a given email or `null`. Used to detect “returning guest (no account)” before showing the create-account prompt.
- **Sign-up prefill:** Sign-up route supports a query parameter (e.g. `?email=...`) so the booking flow can open sign-up with the guest’s email pre-filled when they choose “Create account”.
- **Linking:** No change to linking logic; `AuthService` and `linkClientAndAppointmentsToUser` already combine client + appointments by email when the user signs up.
