/*
 * Filename: update_app_version_firestore.js
 * Purpose: Set Firestore app_version/latest to the given version and build so the app forces this version (except in dev)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Firebase Admin SDK
 * Platform Compatibility: Node.js
 *
 * Usage:
 *   node scripts/update_app_version_firestore.js <version> <buildNumber>
 *   Example: node scripts/update_app_version_firestore.js 1.0.0 3
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS (or gcloud application-default login).
 * Run after deploying so the app forces the newly deployed version.
 */

// MARK: - Imports
const admin = require('firebase-admin');

// MARK: - Parse Args
const args = process.argv.slice(2);
const version = args[0];
const buildNumber = args[1];

if (!version || !buildNumber) {
  console.error('Usage: node scripts/update_app_version_firestore.js <version> <buildNumber>');
  console.error('Example: node scripts/update_app_version_firestore.js 1.0.0 3');
  process.exit(1);
}

const buildNum = parseInt(buildNumber, 10);
if (isNaN(buildNum) || buildNum < 0) {
  console.error('buildNumber must be a non-negative integer');
  process.exit(1);
}

// MARK: - Initialize Firebase Admin
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    console.log('✓ Firebase Admin initialized');
  } catch (error) {
    console.error('✗ Failed to initialize Firebase Admin');
    console.error('Set GOOGLE_APPLICATION_CREDENTIALS or run: gcloud auth application-default login');
    process.exit(1);
  }
}

const firestore = admin.firestore();

// MARK: - Update app_version/latest
async function updateAppVersionLatest() {
  const docRef = firestore.collection('app_version').doc('latest');
  const payload = {
    version,
    buildNumber: buildNum,
    forceUpdate: true,
    message: 'A new version is available. Please refresh or update to continue.',
    updateUrl: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await docRef.set(payload, { merge: true });
  console.log(`✓ app_version/latest set to ${version} (Build ${buildNum})`);
  console.log('  Clients on older builds will be forced to update (except in development).');
}

// MARK: - Main
updateAppVersionLatest()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('✗ Error updating app_version:', err.message);
    process.exit(1);
  });
