# Troubleshooting: flutter pub get Stuck

## Issue: `flutter pub get` Gets Stuck

If `flutter pub get` hangs or gets stuck, try these solutions in order:

## Solution 1: Clear Flutter Cache

```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

# Clear Flutter cache
flutter clean

# Clear pub cache
flutter pub cache repair

# Try again
flutter pub get
```

## Solution 2: Delete Lock Files

```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

# Delete lock files if they exist
Remove-Item -Path "pubspec.lock" -ErrorAction SilentlyContinue
Remove-Item -Path ".packages" -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -ErrorAction SilentlyContinue

# Try again
flutter pub get
```

## Solution 3: Use Verbose Mode

See what's happening:

```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"
flutter pub get --verbose
```

This will show which package is causing the hang.

## Solution 4: Install Dependencies One by One

If a specific package is causing issues, temporarily comment it out in `pubspec.yaml`, then add them back one by one.

## Solution 5: Check Network/Firewall

Some packages might be blocked:
- Check if you're behind a corporate firewall
- Try using a VPN
- Check if GitHub/pub.dev is accessible

## Solution 6: Use Alternative Pub Server

If pub.dev is slow:

```powershell
# Set alternative pub server (if available)
# export PUB_HOSTED_URL=https://pub.flutter-io.cn  # China mirror
```

## Solution 7: Update Flutter

Make sure Flutter is up to date:

```powershell
flutter upgrade
flutter doctor
```

## Solution 8: Manual Dependency Installation

If all else fails, try installing packages manually:

```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

# Install core packages first
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore

# Then add others gradually
```

## Common Causes

1. **Network Issues**: Slow or blocked connection to pub.dev
2. **Corrupted Cache**: Flutter pub cache is corrupted
3. **Lock File Conflicts**: Conflicting dependency versions
4. **Firewall/Proxy**: Corporate network blocking package downloads
5. **Disk Space**: Not enough disk space for packages
6. **Antivirus**: Antivirus software blocking downloads

## Quick Fix Script

Run this PowerShell script:

```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

Write-Host "Cleaning Flutter..." -ForegroundColor Yellow
flutter clean

Write-Host "Removing lock files..." -ForegroundColor Yellow
Remove-Item -Path "pubspec.lock" -ErrorAction SilentlyContinue
Remove-Item -Path ".packages" -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -ErrorAction SilentlyContinue

Write-Host "Repairing pub cache..." -ForegroundColor Yellow
flutter pub cache repair

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get --verbose
```

## If Still Stuck

1. **Check Flutter Doctor**:
   ```powershell
   flutter doctor -v
   ```

2. **Check Disk Space**:
   ```powershell
   Get-PSDrive C
   ```

3. **Check Network**:
   ```powershell
   Test-NetConnection pub.dev -Port 443
   ```

4. **Try Different Network**: Use mobile hotspot or different WiFi

5. **Check Antivirus Logs**: See if packages are being blocked

## Alternative: Skip Problematic Packages

If a specific package is causing issues, you can temporarily comment it out in `pubspec.yaml` and add it back later once the core setup is complete.

## Next Steps After Fix

Once `flutter pub get` completes:

1. Generate model files:
   ```powershell
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. Configure Firebase:
   ```powershell
   flutterfire configure --project=ari-s-esthetician-app
   ```
