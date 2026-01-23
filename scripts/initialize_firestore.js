/*
 * Filename: initialize_firestore.js
 * Purpose: Auto-create default Firestore documents and collections on first setup
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Firebase Admin SDK
 * Platform Compatibility: Node.js
 * 
 * Usage:
 *   1. Install Firebase Admin SDK: npm install firebase-admin
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable to your service account key
 *   3. Run: node scripts/initialize_firestore.js
 * 
 * This script is idempotent - safe to run multiple times without creating duplicates
 */

// MARK: - Imports
const admin = require('firebase-admin');

// MARK: - Initialize Firebase Admin
// Initialize with service account or application default credentials
if (!admin.apps.length) {
  try {
    // Try to use application default credentials
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    console.log('✓ Firebase Admin initialized with application default credentials');
  } catch (error) {
    console.error('✗ Failed to initialize Firebase Admin');
    console.error('Make sure GOOGLE_APPLICATION_CREDENTIALS is set or service account key is provided');
    process.exit(1);
  }
}

const firestore = admin.firestore();
const timestamp = admin.firestore.FieldValue.serverTimestamp();

// MARK: - Default Business Settings
/**
 * Creates default business settings document if it doesn't exist
 * @returns {Promise<void>}
 */
async function initializeBusinessSettings() {
  try {
    console.log('\n📋 Initializing business settings...');
    
    const settingsRef = firestore.collection('business_settings').doc('main');
    const settingsDoc = await settingsRef.get();
    
    if (settingsDoc.exists) {
      console.log('✓ Business settings already exist, skipping creation');
      return;
    }
    
    // Create default business settings
    const defaultSettings = {
      businessName: 'Ari\'s Esthetician',
      businessEmail: 'info@arisesthetician.com',
      businessPhone: '(555) 123-4567',
      businessAddress: null,
      logoUrl: null,
      primaryColorHex: null,
      secondaryColorHex: null,
      websiteUrl: null,
      facebookUrl: null,
      instagramUrl: null,
      twitterUrl: null,
      weeklyHours: [],
      cancellationWindowHours: 24,
      latePolicyText: 'Please arrive on time for your appointment. Late arrivals may result in shortened service time.',
      noShowPolicyText: 'Deposits are non-refundable for no-shows. Please cancel at least 24 hours in advance.',
      bookingPolicyText: 'A non-refundable deposit is required to confirm your appointment.',
      timezone: 'America/New_York',
      googleCalendarId: null,
      stripePublishableKey: null,
      stripeSecretKey: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    };
    
    await settingsRef.set(defaultSettings);
    console.log('✓ Default business settings created');
    console.log('  Note: Update these settings in the admin dashboard');
    
  } catch (error) {
    console.error('✗ Error initializing business settings:', error);
    throw error;
  }
}

// MARK: - Default Services
/**
 * Creates default service documents if none exist
 * @returns {Promise<void>}
 */
async function initializeDefaultServices() {
  try {
    console.log('\n💆 Initializing default services...');
    
    const servicesRef = firestore.collection('services');
    const servicesSnapshot = await servicesRef.limit(1).get();
    
    if (!servicesSnapshot.empty) {
      console.log('✓ Services already exist, skipping creation');
      return;
    }
    
    // Create default services
    const defaultServices = [
      {
        name: 'Facial Treatment',
        description: 'Deep cleansing facial with exfoliation and hydration',
        durationMinutes: 60,
        priceCents: 15000, // $150.00
        depositAmountCents: 5000, // $50.00
        bufferTimeBeforeMinutes: 10,
        bufferTimeAfterMinutes: 10,
        isActive: true,
        displayOrder: 1,
        createdAt: timestamp,
        updatedAt: timestamp,
      },
      {
        name: 'Eyebrow Shaping',
        description: 'Professional eyebrow shaping and styling',
        durationMinutes: 30,
        priceCents: 5000, // $50.00
        depositAmountCents: 2000, // $20.00
        bufferTimeBeforeMinutes: 5,
        bufferTimeAfterMinutes: 5,
        isActive: true,
        displayOrder: 2,
        createdAt: timestamp,
        updatedAt: timestamp,
      },
      {
        name: 'Lash Extensions',
        description: 'Full set of premium lash extensions',
        durationMinutes: 120,
        priceCents: 25000, // $250.00
        depositAmountCents: 7500, // $75.00
        bufferTimeBeforeMinutes: 15,
        bufferTimeAfterMinutes: 15,
        isActive: true,
        displayOrder: 3,
        createdAt: timestamp,
        updatedAt: timestamp,
      },
    ];
    
    const batch = firestore.batch();
    defaultServices.forEach((service) => {
      const serviceRef = servicesRef.doc();
      batch.set(serviceRef, service);
    });
    
    await batch.commit();
    console.log(`✓ Created ${defaultServices.length} default services`);
    console.log('  Note: You can edit or add more services in the admin dashboard');
    
  } catch (error) {
    console.error('✗ Error initializing default services:', error);
    throw error;
  }
}

// MARK: - Verify Collections
/**
 * Verifies that all required collections exist (creates empty if needed)
 * @returns {Promise<void>}
 */
async function verifyCollections() {
  try {
    console.log('\n🔍 Verifying collections...');
    
    const requiredCollections = [
      'users',
      'services',
      'appointments',
      'clients',
      'business_settings',
      'payments',
      'availability',
    ];
    
    // Firestore creates collections automatically when documents are added
    // So we just verify they're accessible
    for (const collectionName of requiredCollections) {
      try {
        const collectionRef = firestore.collection(collectionName);
        await collectionRef.limit(1).get();
        console.log(`  ✓ ${collectionName} collection accessible`);
      } catch (error) {
        console.warn(`  ⚠ Warning: ${collectionName} collection may not be accessible:`, error.message);
      }
    }
    
  } catch (error) {
    console.error('✗ Error verifying collections:', error);
    throw error;
  }
}

// MARK: - Main Initialization Function
/**
 * Runs all initialization steps
 * @returns {Promise<void>}
 */
async function initializeFirestore() {
  try {
    console.log('=== Firestore Initialization Script ===\n');
    console.log('This script will create default documents if they don\'t exist.');
    console.log('It is safe to run multiple times.\n');
    
    // Verify collections
    await verifyCollections();
    
    // Initialize business settings
    await initializeBusinessSettings();
    
    // Initialize default services
    await initializeDefaultServices();
    
    console.log('\n✅ Firestore initialization complete!');
    console.log('\nNext steps:');
    console.log('  1. Update business settings in the admin dashboard');
    console.log('  2. Add or modify services as needed');
    console.log('  3. Create an admin user if you haven\'t already');
    console.log('     Run: node scripts/create_admin_user.js <email> <password>');
    
  } catch (error) {
    console.error('\n✗ Firestore initialization failed:', error);
    process.exit(1);
  }
}

// MARK: - Main Execution
// Run the initialization
initializeFirestore()
  .then(() => {
    // Close Firebase Admin
    return admin.app().delete();
  })
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });

// Suggestions For Features and Additions Later:
// - Add option to reset/clear all default data
// - Add option to create sample appointments for testing
// - Add option to create sample clients for testing
// - Add configuration file for customizing default values
// - Add migration support for updating existing documents
