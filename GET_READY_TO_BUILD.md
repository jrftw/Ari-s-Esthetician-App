# Get Ready to Build - Step by Step

## ⚠️ Current Status: **NOT READY** - Complete These Steps First

The app code is complete, but you need to set up the Flutter project structure and configure Firebase before building.

## Quick Answer

**Can you test on web now?** ❌ **No** - Need to run setup first  
**Can you build for iOS/Android?** ❌ **No** - Need to run setup first

**After setup?** ✅ **Yes** - You can test on web immediately, and build for iOS/Android

## Required Setup (5-10 minutes)

### Step 1: Initialize Flutter Project Structure ⚠️ CRITICAL

Your project is missing the platform folders. Run:

```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"
flutter create .
```

**When prompted**: Choose **NO** to overwrite existing files (to keep your code).

This creates:
- `android/` - Android build configuration
- `ios/` - iOS build configuration  
- `web/` - Web build configuration
- `test/` - Test files

### Step 2: Install Dependencies

```powershell
flutter pub get
```

### Step 3: Generate Model Files

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

Generates: `*.g.dart` files for JSON serialization

### Step 4: Configure Firebase ⚠️ REQUIRED

```powershell
flutterfire configure --project=ari-s-esthetician-app
```

**Prerequisites:**
```powershell
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Install FlutterFire CLI (if not installed)
dart pub global activate flutterfire_cli
```

This generates `lib/core/config/firebase_options.dart` with your Firebase config.

### Step 5: Test on Web ✅

```powershell
flutter run -d chrome
```

The app will launch in Chrome. You'll see:
- ✅ Splash screen
- ✅ Navigation working
- ✅ Theme applied
- ⚠️ Placeholder screens (booking, admin panels)

## Build Commands (After Setup)

### Web
```powershell
# Development
flutter run -d chrome

# Production build
flutter build web
```

### Android
```powershell
# Development
flutter run -d android

# Release APK
flutter build apk

# Release App Bundle (for Play Store)
flutter build appbundle
```

### iOS (Requires Mac)
```powershell
# Development
flutter run -d ios

# Release (requires Xcode)
flutter build ios
flutter build ipa
```

## What Works After Setup

✅ **Will Work:**
- App launches and runs
- Navigation between screens
- Theme and styling (sunflower colors)
- Splash screen
- Login screen UI
- Admin dashboard navigation
- Firebase connection (if configured)

⚠️ **Placeholders (Need Implementation):**
- Client booking screen (shows "To be implemented")
- Admin services screen (shows "To be implemented")
- Admin appointments screen (shows "To be implemented")
- Admin clients screen (shows "To be implemented")
- Admin settings screen (shows "To be implemented")

## Complete Setup Script

Copy and paste this entire block:

```powershell
# Navigate to project
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

# Step 1: Initialize Flutter project (choose NO when prompted)
flutter create .

# Step 2: Install dependencies
flutter pub get

# Step 3: Generate model files
flutter pub run build_runner build --delete-conflicting-outputs

# Step 4: Configure Firebase (interactive - follow prompts)
flutterfire configure --project=ari-s-esthetician-app

# Step 5: Test on web
flutter run -d chrome
```

## Troubleshooting

### "Platform folders missing"
**Fix**: Run `flutter create .` (Step 1)

### "firebase_options.dart not found"
**Fix**: Run `flutterfire configure --project=ari-s-esthetician-app` (Step 4)

### "Model files missing (.g.dart)"
**Fix**: Run `flutter pub run build_runner build --delete-conflicting-outputs` (Step 3)

### "Firebase initialization failed"
**Fix**: 
1. Verify `firebase_options.dart` exists
2. Check Firebase project ID matches
3. Ensure Firebase services enabled in console

### "Cannot find Chrome"
**Fix**: Install Chrome or use `flutter run -d web-server` for any browser

## After Setup Checklist

- [ ] `flutter create .` completed
- [ ] `flutter pub get` completed
- [ ] Model files generated (`.g.dart` files exist)
- [ ] `firebase_options.dart` exists
- [ ] `flutter run -d chrome` works
- [ ] App shows splash screen
- [ ] Navigation works
- [ ] Theme is applied

## Next Steps After Testing

Once the app runs:

1. **Deploy Firestore Rules**:
   ```powershell
   firebase deploy --only firestore
   ```

2. **Create Admin User**:
   - See `scripts/create_admin_user.md`

3. **Start Implementing**:
   - Client booking UI
   - Admin dashboard screens
   - Stripe integration
   - Calendar sync

## Summary

**Before Setup**: ❌ Cannot build or test  
**After Setup**: ✅ Can test on web immediately, can build for iOS/Android

**Time to Setup**: ~5-10 minutes  
**Complexity**: Low (just run commands)

The foundation is solid - you just need to complete the Flutter project initialization and Firebase configuration!
