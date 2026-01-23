# Setup Guide - Ari's Esthetician App

## Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   flutter --version
   ```

2. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

3. **FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

## Initial Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

Run the FlutterFire CLI to configure Firebase for all platforms:

```bash
flutterfire configure --project=ari-s-esthetician-app
```

This will:
- Register your Flutter app with Firebase
- Generate `lib/core/config/firebase_options.dart` with platform-specific configuration
- Set up iOS, Android, and Web Firebase configurations

### 3. Generate Model Files

The project uses `json_serializable` for model serialization. Generate the required files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `lib/models/service_model.g.dart`
- `lib/models/appointment_model.g.dart`
- `lib/models/client_model.g.dart`
- `lib/models/business_settings_model.g.dart`

### 4. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/project/ari-s-esthetician-app)
2. Enable the following services:
   - **Authentication** (Email/Password)
   - **Cloud Firestore** (Start in test mode, then configure rules)
   - **Cloud Functions** (for backend booking validation)
   - **Cloud Storage** (for logo uploads)
   - **Cloud Messaging** (for notifications)

### 5. Firestore Security Rules

Set up Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Services - public read, admin write
    match /services/{serviceId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Appointments - public create, admin read/write
    match /appointments/{appointmentId} {
      allow create: if true;
      allow read, update: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Clients - admin only
    match /clients/{clientId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Business Settings - public read, admin write
    match /business_settings/{settingsId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users - read own, admin write
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### 6. Create Admin User

After setting up authentication, create an admin user:

1. Sign up through the app (will default to 'client' role)
2. In Firestore, manually update the user document:
   - Collection: `users`
   - Document ID: `[user-uid]`
   - Field: `role` = `"admin"`

Or use Firebase Console to create the user and set the role.

### 7. Stripe Setup

1. Create a Stripe account at [stripe.com](https://stripe.com)
2. Get your API keys from the Stripe Dashboard
3. Add Stripe keys to Firestore `business_settings/main` document:
   - `stripePublishableKey`: Your publishable key (safe for client)
   - `stripeSecretKey`: Store in Cloud Functions environment (NOT in client app)

### 8. Google Calendar API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google Calendar API
4. Create service account credentials
5. Download JSON key file
6. Store credentials securely (Cloud Functions environment)
7. Share your Google Calendar with the service account email

## Running the App

### Development

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

### iOS

```bash
flutter run -d ios
```

### Android

```bash
flutter run -d android
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Core functionality
│   ├── config/                  # Firebase, app configuration
│   ├── constants/               # Colors, typography, constants
│   ├── logging/                 # Centralized logging
│   ├── routing/                 # Navigation and routing
│   └── theme/                   # App theme
├── models/                      # Data models
│   ├── service_model.dart
│   ├── appointment_model.dart
│   ├── client_model.dart
│   └── business_settings_model.dart
├── screens/                     # UI screens
│   ├── auth/                    # Authentication screens
│   ├── client/                  # Client-facing screens
│   └── admin/                   # Admin dashboard screens
└── services/                    # Business logic services
    ├── auth_service.dart
    └── firestore_service.dart
```

## Next Steps

1. **Complete Client Booking Flow**
   - Service selection UI
   - Date/time picker
   - Client information form
   - Stripe payment integration
   - Booking confirmation

2. **Complete Admin Dashboard**
   - Services management UI
   - Appointments calendar view
   - Client directory with search
   - Settings management

3. **Backend Services**
   - Cloud Functions for booking validation
   - Email notification service
   - Google Calendar sync service
   - Stripe webhook handlers

4. **Testing**
   - Unit tests for models and services
   - Widget tests for screens
   - Integration tests for booking flow

## Notes

- All business branding is configurable through `BusinessSettingsModel`
- The app uses a centralized theme system for easy customization
- All logging goes through `AppLogger` for consistent debugging
- Role-based routing ensures proper access control
