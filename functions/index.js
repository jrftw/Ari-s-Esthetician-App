/*
 * Filename: index.js
 * Purpose: Firebase Cloud Functions for Stripe payments, appointment emails (confirmation + 24h reminder), and client sync
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: firebase-admin, firebase-functions, nodemailer, stripe
 * Platform Compatibility: Firebase Cloud Functions (Node.js 18)
 */

// MARK: - Imports
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const stripe = require('stripe')(functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY);

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const CLIENTS_COLLECTION = 'clients';
const APPOINTMENTS_COLLECTION = 'appointments';
const BUSINESS_SETTINGS_COLLECTION = 'business_settings';
const BUSINESS_SETTINGS_MAIN_DOC = 'main';

// MARK: - Helper Functions
/**
 * Get Stripe secret key from Firebase config or environment variable
 * @returns {string} Stripe secret key
 */
function getStripeSecretKey() {
  const configKey = functions.config().stripe?.secret_key;
  const envKey = process.env.STRIPE_SECRET_KEY;
  
  if (!configKey && !envKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Stripe secret key not configured. Please set it in Firebase config or environment variables.'
    );
  }
  
  return configKey || envKey;
}

/**
 * Validate request data for payment intent creation
 * @param {Object} data - Request data
 * @throws {functions.https.HttpsError} If validation fails
 */
function validatePaymentIntentData(data) {
  if (!data || typeof data !== 'object') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Request data is required'
    );
  }
  
  if (!data.amount || typeof data.amount !== 'number' || data.amount <= 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Valid amount (in cents) is required'
    );
  }
  
  if (!data.currency || typeof data.currency !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Currency is required'
    );
  }
}

// MARK: - Payment Intent Creation
/**
 * Create a Stripe payment intent
 * This function securely creates payment intents using the server-side Stripe secret key
 * 
 * Expected request data:
 * - amount: number (amount in cents)
 * - currency: string (e.g., 'usd')
 * - customerEmail: string (optional)
 * - metadata: object (optional)
 * 
 * Returns:
 * - id: string (payment intent ID)
 * - clientSecret: string (client secret for confirmation)
 * - created: number (timestamp)
 * - livemode: boolean
 */
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  try {
    // Validate authentication (optional - can be called by anyone for booking)
    // If you want to require auth, uncomment:
    // if (!context.auth) {
    //   throw new functions.https.HttpsError(
    //     'unauthenticated',
    //     'User must be authenticated to create payment intent'
    //   );
    // }
    
    // Validate request data
    validatePaymentIntentData(data);
    
    // Get Stripe secret key
    const stripeSecretKey = getStripeSecretKey();
    const stripeClient = stripe(stripeSecretKey);
    
    // Prepare payment intent parameters
    const paymentIntentParams = {
      amount: data.amount,
      currency: data.currency.toLowerCase(),
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: {
        ...(data.metadata || {}),
        created_at: new Date().toISOString(),
      },
    };
    
    // Add customer email if provided
    if (data.customerEmail) {
      paymentIntentParams.receipt_email = data.customerEmail;
    }
    
    // Create payment intent with Stripe
    const paymentIntent = await stripeClient.paymentIntents.create(paymentIntentParams);
    
    // Return payment intent data (excluding sensitive information)
    return {
      id: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      created: paymentIntent.created,
      livemode: paymentIntent.livemode,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      status: paymentIntent.status,
    };
  } catch (error) {
    console.error('Error creating payment intent:', error);
    
    // Handle Stripe-specific errors
    if (error.type === 'StripeCardError') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Card error: ${error.message}`
      );
    } else if (error.type === 'StripeInvalidRequestError') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid request: ${error.message}`
      );
    } else if (error.type === 'StripeAPIError') {
      throw new functions.https.HttpsError(
        'internal',
        `Stripe API error: ${error.message}`
      );
    } else if (error instanceof functions.https.HttpsError) {
      // Re-throw Firebase HttpsError as-is
      throw error;
    } else {
      // Generic error
      throw new functions.https.HttpsError(
        'internal',
        `Failed to create payment intent: ${error.message || 'Unknown error'}`
      );
    }
  }
});

// MARK: - Payment Intent Validation
/**
 * Validate a payment intent status
 * This function checks if a payment intent exists and is in a valid state
 * 
 * Expected request data:
 * - paymentIntentId: string (Stripe payment intent ID)
 * 
 * Returns:
 * - valid: boolean (whether payment intent is valid)
 * - status: string (payment intent status)
 * - amount: number (amount in cents)
 * - currency: string
 */
exports.validatePaymentIntent = functions.https.onCall(async (data, context) => {
  try {
    // Validate authentication (optional)
    // if (!context.auth) {
    //   throw new functions.https.HttpsError(
    //     'unauthenticated',
    //     'User must be authenticated to validate payment intent'
    //   );
    // }
    
    // Validate request data
    if (!data || !data.paymentIntentId || typeof data.paymentIntentId !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Payment intent ID is required'
      );
    }
    
    // Get Stripe secret key
    const stripeSecretKey = getStripeSecretKey();
    const stripeClient = stripe(stripeSecretKey);
    
    // Retrieve payment intent from Stripe
    const paymentIntent = await stripeClient.paymentIntents.retrieve(data.paymentIntentId);
    
    // Check if payment intent is in a valid state
    const validStatuses = [
      'succeeded',
      'processing',
      'requires_capture',
      'requires_confirmation',
      'requires_payment_method',
    ];
    
    const isValid = validStatuses.includes(paymentIntent.status);
    
    return {
      valid: isValid,
      status: paymentIntent.status,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      id: paymentIntent.id,
    };
  } catch (error) {
    console.error('Error validating payment intent:', error);
    
    // Handle Stripe-specific errors
    if (error.type === 'StripeInvalidRequestError' && error.code === 'resource_missing') {
      // Payment intent not found
      return {
        valid: false,
        status: 'not_found',
        error: 'Payment intent not found',
      };
    } else if (error instanceof functions.https.HttpsError) {
      // Re-throw Firebase HttpsError as-is
      throw error;
    } else {
      // Generic error
      throw new functions.https.HttpsError(
        'internal',
        `Failed to validate payment intent: ${error.message || 'Unknown error'}`
      );
    }
  }
});

// MARK: - Email (SMTP Config + Helpers)
/**
 * Get SMTP configuration from Firebase config or environment variables.
 * Required: smtp.user, smtp.pass. Optional: smtp.host (default gmail), smtp.port (default 587), mail.from.
 * @returns {{ user: string, pass: string, host: string, port: number, from: string }}
 */
function getAriSmtpConfig() {
  const config = functions.config();
  const smtp = config.smtp || {};
  const mail = config.mail || {};
  const user = smtp.user || process.env.SMTP_USER;
  const pass = smtp.pass || process.env.SMTP_PASS;
  if (!user || !pass) {
    throw new Error(
      'SMTP not configured. Set firebase functions:config:set smtp.user="..." smtp.pass="..." (and optionally smtp.host, smtp.port, mail.from). See EMAIL_SETUP.md.'
    );
  }
  return {
    user,
    pass,
    host: smtp.host || process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(smtp.port || process.env.SMTP_PORT || '587', 10),
    from: mail.from || process.env.MAIL_FROM || user,
  };
}

/**
 * Create nodemailer transport from Ari SMTP config.
 * @returns {nodemailer.Transporter}
 */
function createAriMailTransport() {
  const cfg = getAriSmtpConfig();
  return nodemailer.createTransport({
    host: cfg.host,
    port: cfg.port,
    secure: cfg.port === 465,
    auth: { user: cfg.user, pass: cfg.pass },
  });
}

/**
 * Send a single email. Uses Ari SMTP config for from address.
 * @param {nodemailer.Transporter} transport
 * @param {string} to - Recipient email
 * @param {string} subject - Email subject
 * @param {string} html - HTML body
 * @param {string} [text] - Plain text body (optional)
 * @param {string} [replyTo] - Reply-To header (optional)
 * @returns {Promise<{ success: boolean, messageId?: string }>}
 */
async function ariSendMail(transport, to, subject, html, text, replyTo) {
  const cfg = getAriSmtpConfig();
  const from = cfg.from;
  const options = {
    from: typeof from === 'string' && from.includes('<') ? from : `${from}`,
    to,
    subject,
    html,
    text: text || undefined,
    replyTo: replyTo || undefined,
  };
  const info = await transport.sendMail(options);
  return { success: true, messageId: info.messageId };
}

// MARK: - Callable: Get Email Config Status
/**
 * Returns whether SMTP is configured so the app can show/hide email-related messaging.
 * Does not expose any secrets. Backwards compatible: safe to call from clients.
 * Returns: { configured: boolean }
 */
exports.getEmailConfigStatus = functions.https.onCall(async (data, context) => {
  try {
    getAriSmtpConfig();
    return { configured: true };
  } catch (err) {
    return { configured: false };
  }
});

// MARK: - Callable: Send Appointment Confirmation Email
/**
 * Sends appointment confirmation email to the client.
 * Called by the Flutter app after a booking is completed.
 * Expects: appointmentId, clientEmail, clientName, serviceName, appointmentDate, appointmentTime,
 * appointmentDateFormatted, depositAmount, businessName, businessEmail, businessPhone, businessAddress.
 */
exports.sendAppointmentConfirmationEmail = functions.https.onCall(async (data, context) => {
  if (!data || !data.clientEmail || !data.serviceName) {
    throw new functions.https.HttpsError('invalid-argument', 'clientEmail and serviceName are required');
  }
  const clientName = data.clientName || 'Client';
  const appointmentDateFormatted = data.appointmentDateFormatted || data.appointmentDate || '';
  const appointmentTime = data.appointmentTime || '';
  const depositAmount = data.depositAmount || '';
  const businessName = data.businessName || 'Business';
  const businessEmail = data.businessEmail || '';
  const businessPhone = data.businessPhone || '';
  const businessAddress = data.businessAddress || '';

  const subject = `Appointment Confirmed – ${businessName}`;
  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>${subject}</title></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #FFD700; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
    <h1 style="color: #5D4037; margin: 0;">${businessName}</h1>
  </div>
  <div style="background-color: #fff; padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
    <h2 style="color: #5D4037;">Appointment Confirmed!</h2>
    <p>Dear ${clientName},</p>
    <p>Your appointment has been successfully confirmed. We're looking forward to seeing you!</p>
    <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <h3 style="color: #5D4037; margin-top: 0;">Appointment Details</h3>
      <p><strong>Service:</strong> ${data.serviceName}</p>
      <p><strong>Date:</strong> ${appointmentDateFormatted}</p>
      <p><strong>Time:</strong> ${appointmentTime}</p>
      <p><strong>Deposit Paid:</strong> ${depositAmount}</p>
    </div>
    <p><strong>What to expect:</strong></p>
    <ul>
      <li>Please arrive 10 minutes early for your appointment</li>
      <li>A reminder will be sent 24 hours before your appointment</li>
      <li>If you need to reschedule or cancel, please contact us at least 24 hours in advance</li>
    </ul>
    ${businessAddress ? `<p><strong>Location:</strong><br>${businessAddress}</p>` : ''}
    ${businessPhone ? `<p><strong>Phone:</strong> ${businessPhone}</p>` : ''}
    <p>Thank you for choosing ${businessName}!</p>
    <p>Best regards,<br>${businessName}</p>
  </div>
  <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
    <p>This is an automated email. Please do not reply to this message.</p>
  </div>
</body>
</html>`;
  const text = `Appointment Confirmation – ${businessName}\n\nDear ${clientName},\n\nYour appointment has been successfully confirmed.\n\nService: ${data.serviceName}\nDate: ${appointmentDateFormatted}\nTime: ${appointmentTime}\nDeposit Paid: ${depositAmount}\n\nA reminder will be sent 24 hours before your appointment.\n\nThank you for choosing ${businessName}!`;

  try {
    const transport = createAriMailTransport();
    const result = await ariSendMail(transport, data.clientEmail, subject, html, text, businessEmail || undefined);
    return result;
  } catch (err) {
    console.error('sendAppointmentConfirmationEmail failed:', err);
    throw new functions.https.HttpsError('internal', `Failed to send confirmation email: ${err.message}`);
  }
});

// MARK: - Callable: Send Appointment Reminder Email
/**
 * Sends 24-hour (or day-of) reminder email to the client.
 * Expects: appointmentId, clientEmail, clientName, serviceName, appointmentDate, appointmentTime,
 * appointmentDateFormatted, reminderType ('24hour' or 'dayOf'), businessName, businessEmail, businessPhone.
 */
exports.sendAppointmentReminderEmail = functions.https.onCall(async (data, context) => {
  if (!data || !data.clientEmail || !data.serviceName) {
    throw new functions.https.HttpsError('invalid-argument', 'clientEmail and serviceName are required');
  }
  const clientName = data.clientName || 'Client';
  const appointmentDateFormatted = data.appointmentDateFormatted || data.appointmentDate || '';
  const appointmentTime = data.appointmentTime || '';
  const businessName = data.businessName || 'Business';
  const businessEmail = data.businessEmail || '';
  const businessPhone = data.businessPhone || '';
  const reminderType = data.reminderType || '24hour';

  const subject = `Reminder: Your appointment tomorrow – ${businessName}`;
  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>${subject}</title></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #FFD700; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
    <h1 style="color: #5D4037; margin: 0;">${businessName}</h1>
  </div>
  <div style="background-color: #fff; padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
    <h2 style="color: #5D4037;">Appointment Reminder</h2>
    <p>Hi ${clientName},</p>
    <p>This is a friendly reminder that you have an appointment coming up.</p>
    <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <h3 style="color: #5D4037; margin-top: 0;">Appointment Details</h3>
      <p><strong>Service:</strong> ${data.serviceName}</p>
      <p><strong>Date:</strong> ${appointmentDateFormatted}</p>
      <p><strong>Time:</strong> ${appointmentTime}</p>
    </div>
    <p>Please arrive 10 minutes early. If you need to reschedule or cancel, please contact us as soon as possible.</p>
    ${businessPhone ? `<p><strong>Phone:</strong> ${businessPhone}</p>` : ''}
    <p>We look forward to seeing you!</p>
    <p>Best regards,<br>${businessName}</p>
  </div>
  <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
    <p>This is an automated reminder.</p>
  </div>
</body>
</html>`;
  const text = `Appointment Reminder – ${businessName}\n\nHi ${clientName},\n\nYou have an appointment coming up.\n\nService: ${data.serviceName}\nDate: ${appointmentDateFormatted}\nTime: ${appointmentTime}\n\nPlease arrive 10 minutes early. We look forward to seeing you!\n\n${businessName}`;

  try {
    const transport = createAriMailTransport();
    const result = await ariSendMail(transport, data.clientEmail, subject, html, text, businessEmail || undefined);
    return result;
  } catch (err) {
    console.error('sendAppointmentReminderEmail failed:', err);
    throw new functions.https.HttpsError('internal', `Failed to send reminder email: ${err.message}`);
  }
});

// MARK: - Callable: Send Appointment Cancellation Email
/**
 * Sends cancellation confirmation to the client.
 * Expects: clientEmail, clientName, serviceName, appointmentDate, reason, businessName, businessEmail.
 */
exports.sendAppointmentCancellationEmail = functions.https.onCall(async (data, context) => {
  if (!data || !data.clientEmail) {
    throw new functions.https.HttpsError('invalid-argument', 'clientEmail is required');
  }
  const clientName = data.clientName || 'Client';
  const businessName = data.businessName || 'Business';
  const businessEmail = data.businessEmail || '';
  const subject = `Appointment Cancelled – ${businessName}`;
  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>${subject}</title></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #f5f5f5; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
    <h1 style="color: #5D4037; margin: 0;">${businessName}</h1>
  </div>
  <div style="background-color: #fff; padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
    <h2 style="color: #5D4037;">Appointment Cancelled</h2>
    <p>Dear ${clientName},</p>
    <p>Your appointment for ${data.serviceName || 'your service'} on ${data.appointmentDate || 'the scheduled date'} has been cancelled.</p>
    ${data.reason ? `<p><strong>Reason:</strong> ${data.reason}</p>` : ''}
    <p>If you would like to book again, please visit us or contact us.</p>
    <p>Best regards,<br>${businessName}</p>
  </div>
</body>
</html>`;
  const text = `Appointment Cancelled – ${businessName}\n\nDear ${clientName},\n\nYour appointment has been cancelled.${data.reason ? `\nReason: ${data.reason}` : ''}\n\n${businessName}`;

  try {
    const transport = createAriMailTransport();
    const result = await ariSendMail(transport, data.clientEmail, subject, html, text, businessEmail || undefined);
    return result;
  } catch (err) {
    console.error('sendAppointmentCancellationEmail failed:', err);
    throw new functions.https.HttpsError('internal', `Failed to send cancellation email: ${err.message}`);
  }
});

// MARK: - Scheduled: Send 24-Hour Reminder Emails
/**
 * Runs every 15 minutes. Finds appointments starting in ~24 hours that have not yet
 * had a reminder sent, and sends the reminder email then sets reminderEmailSentAt.
 */
function ariReminderWindowStart() {
  const d = new Date();
  d.setTime(d.getTime() + (24 * 60 * 60 * 1000) - (30 * 60 * 1000)); // 23.5h from now
  return d;
}
function ariReminderWindowEnd() {
  const d = new Date();
  d.setTime(d.getTime() + (24 * 60 * 60 * 1000) + (30 * 60 * 1000)); // 24.5h from now
  return d;
}

exports.scheduleAppointmentReminderEmails = functions.pubsub
  .schedule('every 15 minutes')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    let transport;
    try {
      transport = createAriMailTransport();
    } catch (err) {
      console.log('scheduleAppointmentReminderEmails: SMTP not configured, skipping.', err.message);
      return null;
    }

    const start = admin.firestore.Timestamp.fromDate(ariReminderWindowStart());
    const end = admin.firestore.Timestamp.fromDate(ariReminderWindowEnd());

    const snapshot = await db.collection(APPOINTMENTS_COLLECTION)
      .where('startTime', '>=', start)
      .where('startTime', '<=', end)
      .get();

    const businessSettingsSnap = await db.collection(BUSINESS_SETTINGS_COLLECTION).doc(BUSINESS_SETTINGS_MAIN_DOC).get();
    const businessSettings = businessSettingsSnap.exists ? businessSettingsSnap.data() : null;
    const businessName = (businessSettings && businessSettings.businessName) || 'Business';
    const businessEmail = (businessSettings && businessSettings.businessEmail) || '';
    const businessPhone = (businessSettings && businessSettings.businessPhone) || '';

    let sent = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (data.status === 'canceled') continue;
      if (data.reminderEmailSentAt != null) continue;

      const clientEmail = (data.clientEmail || '').trim();
      if (!clientEmail) continue;

      const clientName = [data.clientFirstName, data.clientLastName].filter(Boolean).join(' ') || 'Client';
      const serviceName = (data.serviceSnapshot && data.serviceSnapshot.name) ? data.serviceSnapshot.name : (data.serviceName || 'Service');
      let appointmentDateFormatted = '';
      let appointmentTime = '';
      if (data.startTime && data.startTime.toDate) {
        const dt = data.startTime.toDate();
        appointmentDateFormatted = dt.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
        appointmentTime = dt.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
      }

      const subject = `Reminder: Your appointment tomorrow – ${businessName}`;
      const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>${subject}</title></head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #FFD700; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
    <h1 style="color: #5D4037; margin: 0;">${businessName}</h1>
  </div>
  <div style="background-color: #fff; padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
    <h2 style="color: #5D4037;">Appointment Reminder</h2>
    <p>Hi ${clientName},</p>
    <p>This is a friendly reminder that you have an appointment coming up in 24 hours.</p>
    <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <h3 style="color: #5D4037; margin-top: 0;">Appointment Details</h3>
      <p><strong>Service:</strong> ${serviceName}</p>
      <p><strong>Date:</strong> ${appointmentDateFormatted}</p>
      <p><strong>Time:</strong> ${appointmentTime}</p>
    </div>
    <p>Please arrive 10 minutes early. If you need to reschedule or cancel, please contact us as soon as possible.</p>
    ${businessPhone ? `<p><strong>Phone:</strong> ${businessPhone}</p>` : ''}
    <p>We look forward to seeing you!</p>
    <p>Best regards,<br>${businessName}</p>
  </div>
  <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
    <p>This is an automated reminder.</p>
  </div>
</body>
</html>`;
      const text = `Appointment Reminder – ${businessName}\n\nHi ${clientName},\n\nYou have an appointment in 24 hours.\n\nService: ${serviceName}\nDate: ${appointmentDateFormatted}\nTime: ${appointmentTime}\n\nPlease arrive 10 minutes early. We look forward to seeing you!\n\n${businessName}`;

      try {
        await ariSendMail(transport, clientEmail, subject, html, text, businessEmail || undefined);
        await doc.ref.update({
          reminderEmailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        sent++;
      } catch (err) {
        console.error('scheduleAppointmentReminderEmails: failed to send or update for', doc.id, err);
      }
    }

    if (sent > 0) {
      console.log('scheduleAppointmentReminderEmails: sent', sent, 'reminder(s)');
    }
    return null;
  });

// MARK: - Directory Sync (Every Appointment → Client Directory)
// When any appointment is created (guest, logged-in user, or admin test), sync
// name, email, and phone to the clients collection so the director always has
// current contact info. Runs with Admin SDK (no security rules).
// Idempotent: match by email; create or update. Always overwrite name/phone with
// latest booking so director sees most recent info.
function ariSyncClientFromAppointmentData(data) {
  const firstName = (data.clientFirstName || '').trim();
  const lastName = (data.clientLastName || '').trim();
  const email = (data.clientEmail || '').trim();
  const phone = (data.clientPhone || '').trim();
  const userId = data.userId || null;
  const startTime = data.startTime || null;

  if (!email) {
    console.warn('ariSyncClientFromAppointment: missing clientEmail, skipping sync');
    return Promise.resolve();
  }

  return db.collection(CLIENTS_COLLECTION)
    .where('email', '==', email)
    .limit(1)
    .get()
    .then((snapshot) => {
      const now = admin.firestore.FieldValue.serverTimestamp();
      const baseClientFields = {
        firstName: firstName || '',
        lastName: lastName || '',
        email,
        phone: phone || '',
        totalAppointments: 1,
        completedAppointments: 0,
        noShowCount: 0,
        totalSpentCents: 0,
        createdAt: now,
        updatedAt: now,
      };
      if (userId) baseClientFields.userId = userId;
      if (startTime) baseClientFields.lastAppointmentAt = startTime;

      if (snapshot.empty) {
        return db.collection(CLIENTS_COLLECTION).add(baseClientFields).then((ref) => {
          console.log('ariSyncClientFromAppointment: client created', ref.id, email);
        });
      }

      const doc = snapshot.docs[0];
      const existing = doc.data();
      const updates = {
        updatedAt: now,
        totalAppointments: (existing.totalAppointments || 0) + 1,
        firstName: firstName !== '' ? firstName : (existing.firstName || ''),
        lastName: lastName !== '' ? lastName : (existing.lastName || ''),
        phone: phone !== '' ? phone : (existing.phone || ''),
      };
      if (userId !== undefined && userId !== null) updates.userId = userId;
      if (startTime) updates.lastAppointmentAt = startTime;

      return doc.ref.update(updates).then(() => {
        console.log('ariSyncClientFromAppointment: client updated', doc.id, email);
      });
    })
    .catch((err) => {
      console.error('ariSyncClientFromAppointment: sync failed', email, err);
      // Do not throw so appointment create is not rolled back
    });
}

exports.onAppointmentCreated = functions.firestore
  .document('appointments/{appointmentId}')
  .onCreate((snap, context) => {
    if (!snap || !snap.data) {
      return Promise.resolve();
    }
    const data = snap.data();
    return ariSyncClientFromAppointmentData(data);
  });

// Suggestions For Features and Additions Later:
// - Add webhook handler for Stripe events (payment succeeded, failed, etc.)
// - Add refund functionality
// - Add payment method management
// - Add subscription payment support
// - Add payment history tracking
// - Add dispute handling
// - Add multi-currency support with conversion
// - Add payment retry logic
// - Add fraud detection integration
// - Make reminder timezone configurable via Firebase config or business_settings
// - Add day-of reminder (e.g. 2 hours before) via scheduled function
// - Add email template customization in admin settings
