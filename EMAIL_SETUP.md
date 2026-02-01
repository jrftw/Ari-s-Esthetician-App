# Auto Emails for Appointments – Setup Guide

**Purpose:** Configure the Ari Esthetician App so that:
1. **Confirmation email** is sent when a client confirms a booking (“You will receive a confirmation email shortly”).
2. **24-hour reminder email** is sent automatically the day before the appointment (“A reminder will be sent 24 hours before your appointment”).

**Author:** Kevin Doyle Jr. / Infinitum Imagery LLC  
**Last Modified:** 2026-01-31  
**Dependencies:** Firebase Blaze plan (paid), SMTP credentials (e.g. Gmail)

---

## Overview

- **Confirmation email:** Sent by the app right after a booking is completed. The Flutter app calls the Cloud Function `sendAppointmentConfirmationEmail`; the function sends the email via SMTP.
- **24-hour reminder:** A scheduled Cloud Function runs every 15 minutes, finds appointments starting in ~24 hours that haven’t had a reminder sent yet, sends the reminder email, and marks the appointment so it isn’t sent again.

Both use the same SMTP configuration (e.g. Gmail or another provider).

---

## 1. Firebase plan

- Sending email from Cloud Functions requires **outbound network access**.
- That is only available on the **Blaze (pay-as-you-go)** plan.
- Upgrade in [Firebase Console](https://console.firebase.google.com) → Project → **Upgrade** if you’re still on Spark (free).

---

## 2. Choose an SMTP provider

### Option A: Gmail (simple)

1. Use a Gmail address (e.g. `yourbusiness@gmail.com`).
2. Turn on **2-Step Verification** for that Google account (Google Account → Security).
3. Create an **App Password**:
   - Google Account → Security → 2-Step Verification → App passwords.
   - Create a new app password for “Mail” / “Other (Custom name)” (e.g. “Ari App”).
   - Copy the 16-character password; you’ll use it as `smtp.pass` below.

Use these values when setting config (Step 3):

- **smtp.host:** `smtp.gmail.com`
- **smtp.port:** `587`
- **smtp.user:** your full Gmail address
- **smtp.pass:** the 16-character app password (not your normal Gmail password)

### Option B: SendGrid, Mailgun, etc.

Use the SMTP credentials from your provider (host, port, user, pass). Set them in Firebase config as in Step 3.

---

## 3. Set Firebase config (SMTP)

From your project root (where `firebase.json` lives), run:

```bash
# Required: SMTP user and password
firebase functions:config:set smtp.user="YOUR_EMAIL@gmail.com"
firebase functions:config:set smtp.pass="YOUR_16_CHAR_APP_PASSWORD"

# Optional (defaults shown – Gmail)
firebase functions:config:set smtp.host="smtp.gmail.com"
firebase functions:config:set smtp.port="587"

# Optional: “From” address (defaults to smtp.user)
firebase functions:config:set mail.from="Ari's Business <yourbusiness@gmail.com>"
```

- Replace `YOUR_EMAIL@gmail.com` and `YOUR_16_CHAR_APP_PASSWORD` with your real Gmail and app password.
- For Gmail you can omit `smtp.host` and `smtp.port`; the code uses these defaults.
- To see current config: `firebase functions:config:get`

---

## 4. Deploy Cloud Functions

1. Install dependencies (includes `nodemailer`):

   ```bash
   cd functions
   npm install
   cd ..
   ```

2. Deploy only functions:

   ```bash
   firebase deploy --only functions
   ```

You should see at least:

- `sendAppointmentConfirmationEmail` (callable)
- `sendAppointmentReminderEmail` (callable)
- `sendAppointmentCancellationEmail` (callable)
- `scheduleAppointmentReminderEmails` (scheduled, every 15 minutes)

---

## 5. Confirm behavior

### Confirmation email

1. In the app, complete a booking (choose service, time, pay deposit, etc.).
2. After success, the app calls `sendAppointmentConfirmationEmail`; the client should receive the confirmation email within a short time.
3. If it doesn’t send, check:
   - Firebase Console → Functions → Logs for `sendAppointmentConfirmationEmail` errors.
   - That `smtp.user` and `smtp.pass` are set correctly and the app password is valid.

### 24-hour reminder

1. The function `scheduleAppointmentReminderEmails` runs every 15 minutes (e.g. :00, :15, :30, :45) in the `America/New_York` timezone.
2. It finds appointments whose `startTime` is between 23.5 and 24.5 hours from the current time, and where `reminderEmailSentAt` is not set and status is not `canceled`.
3. For each such appointment it sends one reminder email and sets `reminderEmailSentAt`.
4. To test without waiting 24 hours you can:
   - Temporarily change the window in `functions/index.js` (e.g. “in 5 minutes” instead of “in 24 hours”), deploy, create an appointment in that window, and wait for the next 15-minute run; or
   - Call the callable `sendAppointmentReminderEmail` from your app or from Firebase Console (e.g. via a small test script) with the same payload the app uses.

---

## 6. Timezone for reminders

Reminder timing is computed in **America/New_York**. To use another timezone, edit `functions/index.js` and change the `.timeZone('...')` value in `scheduleAppointmentReminderEmails` to a valid [TZ name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) (e.g. `'America/Los_Angeles'`), then redeploy:

```bash
firebase deploy --only functions
```

---

## 7. Optional: environment variables instead of config

You can use environment variables instead of `firebase functions:config:set`:

- `SMTP_USER` → smtp user
- `SMTP_PASS` → smtp password
- `SMTP_HOST` (optional, default `smtp.gmail.com`)
- `SMTP_PORT` (optional, default `587`)
- `MAIL_FROM` (optional, default `SMTP_USER`)

Set these in Firebase Console → Project Settings → Service accounts, or in your CI/CD when deploying functions. The code in `functions/index.js` reads these if the corresponding `functions.config()` values are not set.

---

## Summary

| What                         | How |
|-----------------------------|-----|
| “You will receive a confirmation email shortly” | App calls `sendAppointmentConfirmationEmail` after booking; function sends email via SMTP. |
| “A reminder will be sent 24 hours before your appointment” | Scheduled function runs every 15 min, finds appointments in the 24h window, sends reminder and sets `reminderEmailSentAt`. |
| Where to set credentials     | Firebase config: `smtp.user`, `smtp.pass` (and optional `smtp.host`, `smtp.port`, `mail.from`). |
| Deploy                       | `cd functions && npm install && cd ..` then `firebase deploy --only functions`. |

Once SMTP is set and functions are deployed, confirmation and 24-hour reminder emails will run automatically as described above.
