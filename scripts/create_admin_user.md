# Create Admin User Guide

This guide explains how to create an admin user for the Ari's Esthetician App.

## Prerequisites

1. **Firebase Admin SDK Setup**
   - Install Node.js (v14 or higher)
   - Install Firebase Admin SDK:
     ```bash
     npm install firebase-admin
     ```

2. **Service Account Key**
   - Go to [Firebase Console](https://console.firebase.google.com/project/ari-s-esthetician-app/settings/serviceaccounts/adminsdk)
   - Click "Generate New Private Key"
   - Save the JSON file securely
   - Set environment variable:
     ```bash
     # Windows PowerShell
     $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccountKey.json"
     
     # Windows CMD
     set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccountKey.json
     
     # macOS/Linux
     export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
     ```

## Method 1: Using the Script

### Interactive Mode

```bash
node scripts/create_admin_user.js
```

The script will prompt you for:
- Admin email address
- Admin password (minimum 6 characters)

### Command Line Mode

```bash
node scripts/create_admin_user.js admin@example.com yourpassword123
```

## Method 2: Manual Creation via Firebase Console

1. **Create User in Authentication**
   - Go to Firebase Console → Authentication → Users
   - Click "Add User"
   - Enter email and password
   - Click "Add User"

2. **Set Admin Role in Firestore**
   - Go to Firebase Console → Firestore Database
   - Navigate to `users` collection
   - Create a new document with the user's UID as the document ID
   - Add the following fields:
     ```json
     {
       "email": "admin@example.com",
       "role": "admin",
       "createdAt": [timestamp],
       "updatedAt": [timestamp]
     }
     ```

## Method 3: Using Firebase CLI

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Use Firebase CLI to create user (requires custom function)
# Or use the Admin SDK script above
```

## Verification

After creating the admin user:

1. **Test Login**
   - Open the app
   - Navigate to `/login`
   - Enter the admin email and password
   - You should be redirected to `/admin` dashboard

2. **Check Firestore**
   - Verify the user document exists in `users` collection
   - Verify the `role` field is set to `"admin"`

## Troubleshooting

### "Failed to initialize Firebase Admin"
- Make sure `GOOGLE_APPLICATION_CREDENTIALS` is set correctly
- Verify the service account key file exists and is valid
- Check that the service account has proper permissions

### "User already exists"
- The script will update the existing user to admin role
- If user exists but role is not set, the script will add it

### "Permission denied"
- Ensure the service account has "Firebase Admin" role
- Check Firestore security rules allow admin writes

## Security Notes

- **Never commit service account keys to version control**
- **Use strong passwords for admin accounts**
- **Enable 2FA for admin accounts if possible**
- **Rotate service account keys periodically**
- **Limit admin access to necessary personnel only**

## Multiple Admin Users

You can create multiple admin users by running the script multiple times with different email addresses:

```bash
node scripts/create_admin_user.js admin1@example.com password1
node scripts/create_admin_user.js admin2@example.com password2
```

All users with `role: "admin"` in Firestore will have admin access.
