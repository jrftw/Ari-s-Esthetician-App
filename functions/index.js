/*
 * Filename: index.js
 * Purpose: Firebase Cloud Functions for payment processing with Stripe
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: firebase-admin, firebase-functions, stripe
 * Platform Compatibility: Firebase Cloud Functions (Node.js 18)
 */

// MARK: - Imports
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY);

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const CLIENTS_COLLECTION = 'clients';

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

// MARK: - Directory Sync (Guest Checkout)
// When an appointment is created (guest or logged-in), sync client to clients collection
// so directory is reliably updated. Runs with Admin SDK (no security rules).
// Idempotent: match by email; create or update.
function ariSyncClientFromAppointmentData(data) {
  const firstName = data.clientFirstName || '';
  const lastName = data.clientLastName || '';
  const email = (data.clientEmail || '').trim();
  const phone = data.clientPhone || '';
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
      if (snapshot.empty) {
        return db.collection(CLIENTS_COLLECTION).add({
          firstName,
          lastName,
          email,
          phone,
          totalAppointments: 1,
          completedAppointments: 0,
          noShowCount: 0,
          totalSpentCents: 0,
          createdAt: now,
          updatedAt: now,
        }).then((ref) => {
          console.log('ariSyncClientFromAppointment: client created', ref.id, email);
        });
      }
      const doc = snapshot.docs[0];
      const existing = doc.data();
      const updates = {
        updatedAt: now,
        totalAppointments: (existing.totalAppointments || 0) + 1,
      };
      if (firstName && (!existing.firstName || existing.firstName === '')) {
        updates.firstName = firstName;
      }
      if (lastName && (!existing.lastName || existing.lastName === '')) {
        updates.lastName = lastName;
      }
      if (phone && (!existing.phone || existing.phone === '')) {
        updates.phone = phone;
      }
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
