# How to Set Admin/Super Admin Role

After a user (including Ari) creates an account, you need to manually set their role to `admin` or `superAdmin` in Firestore.

## Method 1: Firebase Console (Easiest)

1. **User Creates Account**
   - User goes to `/signup` and creates an account
   - They will be created with `role: "client"` by default

2. **Find User in Firebase Console**
   - Go to [Firebase Console → Authentication](https://console.firebase.google.com/project/ari-s-esthetician-app/authentication/users)
   - Find the user by email
   - Copy their **User UID** (the long string)

3. **Set Admin Role in Firestore**
   - Go to [Firestore Database](https://console.firebase.google.com/project/ari-s-esthetician-app/firestore)
   - Navigate to `users` collection
   - Find or create document with the User UID as document ID
   - Update the `role` field:
     - For regular admin: `"admin"`
     - For super admin: `"superAdmin"`

## Method 2: Using the Script

If you have the Firebase Admin SDK set up:

```powershell
# Set environment variable
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccountKey.json"

# Run the script
node scripts/create_admin_user.js ari@example.com herpassword
```

This will:
- Create the user if they don't exist
- Set their role to `admin` in Firestore

**To set superAdmin instead**, you'll need to manually update Firestore after running the script, or modify the script.

## Method 3: Update Existing User to Admin

If the user already exists:

1. **Get User UID from Firebase Console → Authentication**
2. **Go to Firestore → users collection**
3. **Find document with User UID**
4. **Update `role` field to `"admin"` or `"superAdmin"`**

## Role Differences

- **`client`**: Regular user, can book appointments, view their own appointments
- **`admin`**: Can access admin dashboard, manage services, appointments, clients, settings
- **`superAdmin`**: Same as admin (currently no difference, but can be extended later for additional permissions)

## For Ari (The Esthetician)

1. **Ari creates account** at `/signup` with her email
2. **You set her role** to `"admin"` or `"superAdmin"` in Firestore
3. **She can now log in** at `/login` and access the admin dashboard at `/admin`

## Quick Steps for Ari

```powershell
# 1. Ari goes to the app and clicks "Sign Up"
# 2. She creates account with her email
# 3. You go to Firebase Console
# 4. Find her in Authentication → copy UID
# 5. Go to Firestore → users → create/update document with her UID
# 6. Set role: "admin" or "superAdmin"
# 7. Done! She can now log in as admin
```

## Security Note

- Only users with `admin` or `superAdmin` role can access `/admin` routes
- Regular `client` users are redirected away from admin routes
- All new sign-ups default to `client` role for security
