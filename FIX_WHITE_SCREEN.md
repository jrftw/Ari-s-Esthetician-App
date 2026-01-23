# Fix White Screen Issue

## Problem
The app shows a white screen because Firebase configuration has placeholder values instead of real API keys.

## Quick Fix

### Step 1: Re-run FlutterFire Configuration

```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

# Make sure you're logged into Firebase
firebase login

# Re-configure Firebase (this will update firebase_options.dart with real keys)
flutterfire configure --project=ari-s-esthetician-app
```

**When prompted:**
- Select all platforms (iOS, Android, Web)
- For Android package name: `ari.est`
- For iOS bundle ID: `ari.est`

### Step 2: Verify Configuration

After running `flutterfire configure`, check that `lib/core/config/firebase_options.dart` has real API keys (not `YOUR_WEB_API_KEY`, etc.).

### Step 3: Restart the App

```powershell
# Stop the current app (press 'q' in terminal)
# Then restart:
flutter run -d chrome
```

## What Changed

I've added better error handling:
- ✅ App now shows an error screen if Firebase fails to initialize
- ✅ Error message explains what's wrong
- ✅ Instructions displayed on how to fix it

## If You Still See White Screen

1. **Check Browser Console** (F12 → Console tab):
   - Look for JavaScript errors
   - Look for Firebase initialization errors

2. **Check Terminal Output**:
   - Look for Firebase initialization errors
   - Check if `firebase_options.dart` was updated

3. **Verify Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/project/ari-s-esthetician-app)
   - Make sure Firestore is enabled
   - Make sure Authentication is enabled

## Expected Behavior After Fix

✅ App should show:
- Splash screen (2 seconds)
- Then redirect to booking page (if not logged in)
- Or redirect to admin dashboard (if logged in as admin)

If you see an error screen, it will tell you exactly what's wrong!
