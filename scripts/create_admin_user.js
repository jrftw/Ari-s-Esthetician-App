/*
 * Filename: create_admin_user.js
 * Purpose: Script to create an admin user in Firestore
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Firebase Admin SDK
 * Platform Compatibility: Node.js
 * 
 * Usage:
 *   1. Install Firebase Admin SDK: npm install firebase-admin
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable to your service account key
 *   3. Run: node scripts/create_admin_user.js <email> <password>
 */

// MARK: - Imports
const admin = require('firebase-admin');
const readline = require('readline');

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

const auth = admin.auth();
const firestore = admin.firestore();

// MARK: - Create Admin User Function
/**
 * Creates an admin user in Firebase Auth and sets role in Firestore
 * @param {string} email - Admin email address
 * @param {string} password - Admin password (min 6 characters)
 * @returns {Promise<void>}
 */
async function createAdminUser(email, password) {
  try {
    console.log(`\nCreating admin user: ${email}...`);
    
    // MARK: - Create User in Firebase Auth
    let userRecord;
    try {
      userRecord = await auth.createUser({
        email: email,
        password: password,
        emailVerified: true,
      });
      console.log('✓ User created in Firebase Auth');
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log('ℹ User already exists in Firebase Auth, fetching...');
        userRecord = await auth.getUserByEmail(email);
      } else {
        throw error;
      }
    }
    
    // MARK: - Set Admin Role in Firestore
    const userDocRef = firestore.collection('users').doc(userRecord.uid);
    const userDoc = await userDocRef.get();
    
    if (userDoc.exists) {
      // Update existing user to admin
      await userDocRef.update({
        role: 'admin',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log('✓ User role updated to admin in Firestore');
    } else {
      // Create new user document with admin role
      await userDocRef.set({
        email: email,
        role: 'admin',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log('✓ User document created with admin role in Firestore');
    }
    
    console.log(`\n✓ Admin user created successfully!`);
    console.log(`  User ID: ${userRecord.uid}`);
    console.log(`  Email: ${email}`);
    console.log(`  Role: admin`);
    console.log(`\nYou can now log in to the admin dashboard with this account.`);
    
  } catch (error) {
    console.error('\n✗ Error creating admin user:');
    console.error(error);
    process.exit(1);
  }
}

// MARK: - Interactive Mode
/**
 * Prompts for email and password if not provided as arguments
 */
function promptForCredentials() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  
  return new Promise((resolve) => {
    rl.question('Enter admin email: ', (email) => {
      rl.question('Enter admin password (min 6 characters): ', (password) => {
        rl.close();
        resolve({ email, password });
      });
    });
  });
}

// MARK: - Main Execution
async function main() {
  console.log('=== Create Admin User Script ===\n');
  
  let email, password;
  
  // Check if email and password provided as command line arguments
  if (process.argv.length >= 4) {
    email = process.argv[2];
    password = process.argv[3];
  } else {
    // Interactive mode
    const credentials = await promptForCredentials();
    email = credentials.email;
    password = credentials.password;
  }
  
  // Validate inputs
  if (!email || !email.includes('@')) {
    console.error('✗ Invalid email address');
    process.exit(1);
  }
  
  if (!password || password.length < 6) {
    console.error('✗ Password must be at least 6 characters');
    process.exit(1);
  }
  
  await createAdminUser(email, password);
  
  // Close Firebase Admin
  await admin.app().delete();
  process.exit(0);
}

// Run the script
main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});

// Suggestions For Features and Additions Later:
// - Add password strength validation
// - Add option to create multiple admin users
// - Add option to remove admin role
// - Add email verification option
