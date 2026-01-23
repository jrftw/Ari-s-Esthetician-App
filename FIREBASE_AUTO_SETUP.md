# Firebase Auto-Setup Guide

This guide explains how to use the automated Firebase setup system that creates indexes, rules, storage, and initial documents automatically.

## Overview

The auto-setup system includes:
- ✅ **Firestore Indexes** - Automatically deployed from `firestore.indexes.json`
- ✅ **Firestore Security Rules** - Automatically deployed from `firestore.rules`
- ✅ **Storage Security Rules** - Automatically deployed from `storage.rules`
- ✅ **Default Documents** - Automatically created via initialization script

## Quick Start

### Option 1: Full Automated Deployment (Recommended)

Run the comprehensive deployment script:

```powershell
.\scripts\deploy_firebase.ps1
```

This will:
1. Check prerequisites (Firebase CLI, Node.js, etc.)
2. Deploy Firestore rules and indexes
3. Deploy Storage rules
4. Initialize default Firestore documents

### Option 2: Deploy Only Rules

If you only want to deploy rules and indexes (skip document initialization):

```powershell
.\scripts\deploy_firebase.ps1 -SkipInitialization
```

### Option 3: Deploy Only Rules (No Initialization)

If you only want to deploy rules:

```powershell
.\scripts\deploy_firebase.ps1 -OnlyRules
```

### Option 4: Initialize Documents Only

If you only want to create default documents:

```powershell
.\scripts\deploy_firebase.ps1 -OnlyInitialization
```

## Prerequisites

Before running the deployment script, ensure you have:

1. **Firebase CLI Installed**
   ```powershell
   npm install -g firebase-tools
   ```

2. **Firebase CLI Logged In**
   ```powershell
   firebase login
   ```

3. **Node.js Installed**
   - Download from [nodejs.org](https://nodejs.org/)

4. **Service Account Credentials (for document initialization)**
   - Download service account key from Firebase Console
   - Set environment variable:
     ```powershell
     $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\serviceAccountKey.json"
     ```
   - Or use Application Default Credentials:
     ```powershell
     gcloud auth application-default login
     ```

## Manual Steps

If you prefer to run steps manually:

### 1. Deploy Firestore Rules and Indexes

```powershell
firebase deploy --only firestore
```

This deploys:
- `firestore.rules` - Security rules
- `firestore.indexes.json` - Database indexes

### 2. Deploy Storage Rules

```powershell
firebase deploy --only storage
```

This deploys:
- `storage.rules` - Storage security rules

### 3. Initialize Default Documents

```powershell
node scripts\initialize_firestore.js
```

This creates:
- Default `business_settings/main` document
- Default service documents (if none exist)

## What Gets Created

### Default Business Settings

The initialization script creates a default business settings document at `business_settings/main` with:
- Business name, email, phone
- Default policies (cancellation, late, no-show)
- Empty weekly hours (to be configured)
- Default timezone (America/New_York)

### Default Services

If no services exist, the script creates 3 default services:
1. **Facial Treatment** - 60 minutes, $150.00
2. **Eyebrow Shaping** - 30 minutes, $50.00
3. **Lash Extensions** - 120 minutes, $250.00

You can edit or delete these in the admin dashboard.

## File Structure

```
.
├── firestore.rules              # Firestore security rules
├── firestore.indexes.json       # Firestore indexes
├── storage.rules                # Storage security rules
├── firebase.json                # Firebase configuration
└── scripts/
    ├── deploy_firebase.ps1      # Main deployment script
    ├── initialize_firestore.js  # Document initialization script
    └── create_admin_user.js     # Admin user creation script
```

## Storage Rules Overview

The `storage.rules` file provides:

- **Business Assets** (`/business/*`) - Public read, admin write
- **User Uploads** (`/users/{userId}/*`) - Own read/write, admin read/write
- **Appointment Attachments** (`/appointments/*`) - Admin only
- **Service Images** (`/services/*`) - Public read, admin write
- **Client Documents** (`/clients/*`) - Admin only
- **Temporary Uploads** (`/temp/*`) - Authenticated write, admin read/delete

## Firestore Indexes

The following indexes are automatically created:

1. **Appointments**
   - `startTime` + `status` (ascending)
   - `status` + `startTime` (ascending)

2. **Clients**
   - `lastName` + `firstName` (ascending)
   - `email` (ascending)

3. **Services**
   - `isActive` + `displayOrder` (ascending)

## Verification

After deployment, verify everything is working:

1. **Check Firestore Rules**
   - Go to [Firestore Rules](https://console.firebase.google.com/project/ari-s-esthetician-app/firestore/rules)
   - Verify rules match your local `firestore.rules` file

2. **Check Storage Rules**
   - Go to [Storage Rules](https://console.firebase.google.com/project/ari-s-esthetician-app/storage/rules)
   - Verify rules match your local `storage.rules` file

3. **Check Indexes**
   - Go to [Firestore Indexes](https://console.firebase.google.com/project/ari-s-esthetician-app/firestore/indexes)
   - Wait for indexes to finish building (may take a few minutes)

4. **Check Default Documents**
   - Go to [Firestore Data](https://console.firebase.google.com/project/ari-s-esthetician-app/firestore/data)
   - Verify `business_settings/main` exists
   - Verify default services exist (if initialized)

## Troubleshooting

### "Permission denied" errors

1. Verify rules are deployed:
   ```powershell
   firebase firestore:rules:get
   ```

2. Check user role in Firestore:
   - Verify `users/{userId}` document exists
   - Verify `role` field is set to `"admin"`

### Indexes not building

1. Check index status in Firebase Console
2. Wait a few minutes - indexes can take time to build
3. Verify `firestore.indexes.json` is correctly formatted

### Initialization script fails

1. Check `GOOGLE_APPLICATION_CREDENTIALS` is set correctly
2. Verify service account has Firestore permissions
3. Try running manually: `node scripts\initialize_firestore.js`

### Storage rules not deploying

1. Verify `storage.rules` file exists
2. Check `firebase.json` includes storage configuration
3. Verify Firebase Storage is enabled in Firebase Console

## Next Steps

After successful deployment:

1. **Update Business Settings**
   - Log in to admin dashboard
   - Go to Settings
   - Update business information, hours, policies

2. **Create Admin User** (if not already created)
   ```powershell
   node scripts\create_admin_user.js admin@example.com yourpassword
   ```

3. **Customize Services**
   - Edit default services or add new ones
   - Set pricing, duration, and availability

4. **Configure Availability**
   - Set up business hours
   - Configure time slots

## Script Options

The `deploy_firebase.ps1` script supports these parameters:

- `-SkipInitialization` - Skip document initialization
- `-OnlyRules` - Deploy only rules (Firestore + Storage)
- `-OnlyInitialization` - Only initialize documents (skip rules deployment)

## Idempotency

All scripts are **idempotent** - safe to run multiple times:
- Rules deployment will update existing rules
- Indexes will be created if missing
- Document initialization will skip if documents already exist

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Firebase Console for error messages
3. Check script output for detailed error information
