# Next Steps - Firebase Configuration

## ✅ Completed
- [x] Dependencies installed (`flutter pub get`)
- [x] Model files generated (`build_runner`)
- [x] Firebase CLI installed

## 🔄 Current Step: Refresh Terminal

Firebase CLI was just installed but needs a fresh terminal session to be recognized.

### Solution: Restart Your Terminal

1. **Close your current terminal/PowerShell window**
2. **Open a new terminal/PowerShell window**
3. **Navigate back to the project**:
   ```powershell
   cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"
   ```

### Verify Firebase CLI Works

```powershell
firebase --version
```

You should see something like: `13.x.x` or `12.x.x`

## Step 3: Login to Firebase

```powershell
firebase login
```

This will:
- Open a browser window
- Ask you to sign in with your Google account
- Grant permissions to Firebase CLI

**Important**: Use the same Google account that has access to `ari-s-esthetician-app` project.

## Step 4: Verify Project Access

```powershell
firebase projects:list
```

You should see `ari-s-esthetician-app` in the list.

## Step 5: Set Default Project

```powershell
firebase use ari-s-esthetician-app
```

## Step 6: Install FlutterFire CLI (if not already done)

```powershell
dart pub global activate flutterfire_cli
```

## Step 7: Configure Flutter App

```powershell
flutterfire configure --project=ari-s-esthetician-app
```

**When prompted:**
- Select platforms: **Web**, **Android**, **iOS** (or just Web if you only want to test on web first)
- Follow the prompts to configure each platform

This will generate `lib/core/config/firebase_options.dart` with real API keys.

## Step 8: Deploy Firestore Rules

```powershell
firebase deploy --only firestore
```

This deploys:
- Security rules (`firestore.rules`)
- Database indexes (`firestore.indexes.json`)

## Step 9: Test the App

```powershell
flutter run -d chrome
```

You should see:
- ✅ Splash screen
- ✅ Navigation working
- ✅ Sunflower theme applied
- ✅ Login screen (UI)

## Quick Command Summary

After restarting your terminal, run these in order:

```powershell
# Navigate to project
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

# Verify Firebase CLI
firebase --version

# Login to Firebase
firebase login

# Verify project access
firebase projects:list

# Set default project
firebase use ari-s-esthetician-app

# Install FlutterFire CLI (if needed)
dart pub global activate flutterfire_cli

# Configure Flutter app
flutterfire configure --project=ari-s-esthetician-app

# Deploy Firestore rules
firebase deploy --only firestore

# Test on web
flutter run -d chrome
```

## Troubleshooting

### If `firebase --version` still doesn't work after restarting:

1. **Check npm global bin path**:
   ```powershell
   npm config get prefix
   ```

2. **Add to PATH manually** (if needed):
   - Usually: `C:\Users\kevin\AppData\Roaming\npm`
   - Add to Windows PATH environment variable

3. **Or use full path**:
   ```powershell
   & "$env:APPDATA\npm\firebase.cmd" --version
   ```

### Alternative: Use npx

If PATH issues persist, you can use:
```powershell
npx firebase-tools --version
npx firebase-tools login
npx firebase-tools use ari-s-esthetician-app
```

But it's better to fix the PATH so `firebase` command works directly.
