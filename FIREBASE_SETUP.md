# Firebase Setup Guide

## Issue: Firebase CLI Not Found

The FlutterFire CLI requires the official Firebase CLI to be installed first.

## Step 1: Install Firebase CLI

### Option A: Using npm (Recommended)

```powershell
npm install -g firebase-tools
```

### Option B: Using Standalone Installer

1. Download from: https://firebase.google.com/docs/cli#install_the_firebase_cli
2. Run the installer
3. Restart your terminal

## Step 2: Verify Installation

```powershell
firebase --version
```

You should see something like: `12.x.x` or higher

## Step 3: Login to Firebase

```powershell
firebase login
```

This will:
- Open a browser window
- Ask you to sign in with your Google account
- Grant permissions to Firebase CLI

**Important**: Use the same Google account that has access to the `ari-s-esthetician-app` project.

## Step 4: Verify Project Access

```powershell
firebase projects:list
```

You should see `ari-s-esthetician-app` in the list.

## Step 5: Set Default Project (Optional)

```powershell
firebase use ari-s-esthetician-app
```

## Step 6: Install FlutterFire CLI

```powershell
dart pub global activate flutterfire_cli
```

## Step 7: Configure Flutter App

Now run:

```powershell
flutterfire configure --project=ari-s-esthetician-app
```

This will:
- Ask which platforms to configure (select: Web, Android, iOS)
- Generate `lib/core/config/firebase_options.dart` with real API keys
- Configure each platform

## Troubleshooting

### "firebase: command not found"
- Make sure npm is installed: `npm --version`
- If npm is not installed, install Node.js from: https://nodejs.org/
- After installing, restart your terminal

### "Permission denied"
- On Windows, you may need to run PowerShell as Administrator
- Or use: `npm install -g firebase-tools --force`

### "Project not found"
- Make sure you're logged in with the correct Google account
- Verify you have access to the project in Firebase Console
- Check project ID: `ari-s-esthetician-app`

### "FlutterFire CLI not found"
- Run: `dart pub global activate flutterfire_cli`
- Make sure Dart is in your PATH

## After Configuration

Once `flutterfire configure` completes successfully:

1. **Verify** `lib/core/config/firebase_options.dart` exists and has real API keys (not "YOUR_API_KEY")
2. **Deploy Firestore rules**: `firebase deploy --only firestore`
3. **Test the app**: `flutter run -d chrome`
