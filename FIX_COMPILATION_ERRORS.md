# Fix Compilation Errors

## Quick Fix Commands

Run these commands in your terminal to fix the compilation errors:

### 1. Install Dependencies
```powershell
cd "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"
flutter pub get
```

This will install the `url_launcher` package and all other dependencies.

### 2. Generate Model Files
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the missing `_$ServicePackageOptionFromJson` and `_$ServicePackageOptionToJson` methods in `service_model.dart`.

## What These Errors Mean

### Error 1: `url_launcher` package not found
- **Cause**: The package is in `pubspec.yaml` but hasn't been downloaded yet
- **Fix**: Run `flutter pub get`

### Error 2: Missing generated methods in `service_model.dart`
- **Cause**: The `.g.dart` file hasn't been generated or is out of date
- **Fix**: Run `build_runner` to generate the JSON serialization code

## After Running These Commands

The compilation errors should be resolved and your app should build successfully.

## Note

If you continue to see errors after running these commands:
1. Make sure you're in the correct directory
2. Check that Flutter is properly installed: `flutter doctor`
3. Try cleaning the build: `flutter clean` then `flutter pub get`
