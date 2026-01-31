# Version Forcing Setup Guide

## Overview
The app now includes version forcing functionality that requires users to update to the latest version before using the app. This check is automatically skipped in development mode.

## How It Works

1. **On App Launch**: The app checks the current version against the latest required version stored in Firestore
2. **Version Comparison**: Compares both version number (e.g., "1.0.0") and build number (e.g., 1)
3. **Update Required**: If the app version is older than the required version, a blocking update screen is shown
4. **Development Mode**: Version checks are automatically skipped when `AppVersion.environment == AppEnvironment.development`

## Firestore Setup

### Create Version Document

You need to create a document in the `app_version` collection with the document ID `latest`.

**Collection**: `app_version`  
**Document ID**: `latest`

### Document Structure

```json
{
  "version": "1.0.0",
  "buildNumber": 1,
  "forceUpdate": true,
  "message": "A new version is available with important updates and bug fixes.",
  "updateUrl": "https://apps.apple.com/app/aris-esthetician-app"
}
```

### Field Descriptions

- **version** (string, required): The minimum required version number (e.g., "1.0.0")
- **buildNumber** (number, required): The minimum required build number (e.g., 1)
- **forceUpdate** (boolean, optional): Whether to force the update. Defaults to `true` if not provided
- **message** (string, optional): Custom message to display on the update screen
- **updateUrl** (string, optional): URL to the app store listing. If not provided, a default URL is used

### Example: Requiring Version 1.0.1 Build 2

```json
{
  "version": "1.0.1",
  "buildNumber": 2,
  "forceUpdate": true,
  "message": "Please update to version 1.0.1 to continue using the app.",
  "updateUrl": "https://apps.apple.com/app/aris-esthetician-app"
}
```

## Updating the Required Version (Always Force Newest Deployed Build)

The app forces the **version stored in Firestore `app_version/latest`** (except in development). To always force the **newest deployed version**, update that document when you deploy.

### Option A: Deploy script (recommended)

When you deploy with `deploy_hosting.ps1`, it automatically parses `pubspec.yaml` and runs `scripts/update_app_version_firestore.js` to set `app_version/latest` to the deployed version and build. Ensure `GOOGLE_APPLICATION_CREDENTIALS` is set (or `gcloud auth application-default login`) so the script can write to Firestore.

### Option B: Manual script after deploy

Run after each deploy:

```bash
node scripts/update_app_version_firestore.js <version> <buildNumber>
# Example: node scripts/update_app_version_firestore.js 1.0.0 3
```

### Option C: Manual Firestore update

When you release a new version:

1. Update the version in `lib/core/constants/app_version.dart`:
   ```dart
   static const String version = "1.0.1";
   static const int buildNumber = 2;
   ```

2. Update the version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   ```

3. Update the Firestore document `app_version/latest` with the new required version (and set `forceUpdate: true`)

## Development Mode

Version checking is automatically disabled when:
- `AppVersion.environment == AppEnvironment.development`

To enable version checking in development (for testing), change the environment in `app_version.dart`:
```dart
static const AppEnvironment environment = AppEnvironment.production;
```

## Firestore Rules

The Firestore rules have been updated to allow public read access to the `app_version` collection:

```javascript
match /app_version/{versionId} {
  allow read: if true; // Public read for version checking
  allow write: if isAdmin();
}
```

## Testing

### Test Update Required Screen

1. Set your app version to an older version (e.g., "1.0.0" Build 1)
2. Set the Firestore document to require a newer version (e.g., "1.0.1" Build 2)
3. Launch the app - you should see the update required screen

### Test Development Mode Skip

1. Ensure `AppVersion.environment == AppEnvironment.development`
2. Set Firestore to require a newer version
3. Launch the app - it should skip the version check and launch normally

## Troubleshooting

### Version Check Not Working

- Ensure Firebase is properly initialized
- Check that the `app_version/latest` document exists in Firestore
- Verify Firestore rules allow public read access
- Check app logs for version check errors

### Update Screen Not Showing

- Verify the version comparison logic (check logs)
- Ensure `forceUpdate` is set to `true` in Firestore
- Check that you're not in development mode

### App Stuck on Loading

- Check network connectivity
- Verify Firestore is accessible
- Check app logs for timeout errors (version check has a 10-second timeout)

## Platform Support

### iOS
- Version check works the same as other platforms
- Update button opens App Store
- Button text: "Update from App Store"
- Requires App Store URL in Firestore document or default URL configured

### Android
- Version check works the same as other platforms
- Update button opens Play Store
- Button text: "Update from Play Store"
- Requires Play Store URL in Firestore document or default URL configured

### Web
- Version check works the same as other platforms
- Update button shows refresh dialog with instructions
- Button text: "Refresh Page"
- Users must manually refresh the browser to load new version
- Web apps typically update automatically when browser cache is cleared or page is refreshed

## Notes

- Version check has a 10-second timeout - if it times out, the app will continue (fail open)
- On any error during version check, the app will continue (fail open) to prevent blocking users
- The version check only runs once on app launch
- Version comparison uses semantic versioning (major.minor.patch)
- **All platforms (Web, iOS, Android) use the same version forcing mechanism** - the only difference is how the update is delivered (refresh for web, app store for mobile)
