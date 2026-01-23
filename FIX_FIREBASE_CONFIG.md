# Fix Firebase Configuration

## Issue: Invalid Android Package Name

The Android package name "ari est" is invalid. Package names must:
- Use reverse domain notation (e.g., `com.company.appname`)
- Contain no spaces
- Use lowercase letters, numbers, and dots only

## Solution: Re-run Configuration with Correct Package Name

Run this command again:

```powershell
# Make sure PATH includes npm
$env:Path += ";$env:APPDATA\npm"

# Re-run configuration
flutterfire configure --project=ari-s-esthetician-app
```

**When prompted for Android package name, use:**
```
com.infinitumimagery.arisestheticianapp
```

Or if you prefer a shorter version:
```
com.infinitum.arisesthetician
```

## Complete Configuration Steps

1. **Run the configure command:**
   ```powershell
   $env:Path += ";$env:APPDATA\npm"
   flutterfire configure --project=ari-s-esthetician-app
   ```

2. **Select platforms:** 
   - Use arrow keys and spacebar to select: **web**, **android**, **ios**
   - Press Enter when done

3. **Android package name:**
   - Enter: `com.infinitumimagery.arisestheticianapp`
   - Press Enter

4. **iOS bundle ID:**
   - It will suggest: `com.infinitumimagery.arisestheticianapp`
   - Press Enter to accept (or type a different one)

5. **Follow remaining prompts** for each platform

## After Configuration

Once configuration completes successfully:

```powershell
# Deploy Firestore rules
firebase deploy --only firestore

# Test the app
flutter run -d chrome
```

## Package Name Format

Android package names follow this format:
- `com.[company].[appname]`
- All lowercase
- No spaces or special characters (except dots)
- Example: `com.infinitumimagery.arisestheticianapp`

This matches your iOS bundle ID for consistency.
