# Ari's Esthetician App

**A production-ready Flutter booking application for esthetician businesses with a beautiful sunflower-themed design.**

[![Flutter](https://img.shields.io/badge/Flutter-3.2.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Usage Guide](#usage-guide)
- [Development](#development)
- [Deployment](#deployment)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

---

## 🎯 Overview

Ari's Esthetician App is a comprehensive booking management system designed specifically for esthetician businesses. The application provides a seamless experience for both clients and administrators, featuring a beautiful sunflower-themed UI, secure payment processing, and robust appointment management capabilities.

### Key Highlights

- **Client-Friendly Booking**: Public booking interface with no authentication required
- **Admin Dashboard**: Complete management system for services, appointments, and clients
- **Secure Payments**: Stripe integration for deposit processing
- **Calendar Integration**: Google Calendar sync with Apple Calendar compatibility
- **Email Notifications**: Automated confirmation and reminder emails
- **Double-Booking Prevention**: Backend-validated booking system
- **Configurable Branding**: Fully customizable business settings

---

## ✨ Features

### Client Features
- 📅 **Service Selection**: Browse available services with pricing and duration
- 🗓️ **Appointment Booking**: Select date and time with real-time availability checking
- 💳 **Secure Payments**: Stripe-powered deposit processing
- 📧 **Email Confirmations**: Automatic booking confirmation emails
- 📱 **Calendar Integration**: Add appointments to Google Calendar or Apple Calendar
- ✅ **Booking Confirmation**: Clear confirmation screen with appointment details

### Admin Features
- 🎛️ **Dashboard**: Overview of appointments, clients, and business metrics
- 🔧 **Services Management**: Create, edit, and manage service offerings
- 📊 **Appointments Calendar**: Day/week view of all appointments with status management
- 👥 **Client Directory**: Searchable client database with history tracking
- ⚙️ **Business Settings**: Configure business hours, policies, branding, and integrations
- 🔐 **Role-Based Access**: Secure admin authentication and authorization

### Technical Features
- 🔒 **Firebase Authentication**: Secure user authentication with role management
- 📦 **Cloud Firestore**: Real-time database with optimized queries
- 🛡️ **Security Rules**: Comprehensive Firestore security rules
- 📝 **Centralized Logging**: App-wide logging system for debugging
- 🎨 **Theme System**: Consistent sunflower-themed design system
- 🔄 **State Management**: Riverpod for reactive state management
- 🧭 **Navigation**: Go Router for type-safe navigation

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.2.0+ - Cross-platform UI framework
- **Dart** - Programming language
- **Riverpod** - State management
- **Go Router** - Navigation and routing

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Cloud Functions** - Serverless backend functions
- **Cloud Storage** - File storage
- **Cloud Messaging** - Push notifications

### Third-Party Integrations
- **Stripe** - Payment processing
- **Google Calendar API** - Calendar synchronization
- **Email Service** - Automated email notifications

### Development Tools
- **build_runner** - Code generation
- **json_serializable** - JSON serialization
- **flutter_lints** - Linting rules

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.2.0 or higher)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (included with Flutter)

3. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

4. **FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

5. **Git** (for version control)

6. **IDE** (recommended: VS Code or Android Studio with Flutter plugins)

### Platform-Specific Requirements

- **iOS**: Xcode 14+ (macOS only)
- **Android**: Android Studio with Android SDK
- **Web**: Chrome or Edge browser

---

## 🚀 Installation & Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/jrftw/Ari-s-Esthetician-App.git
cd Ari-s-Esthetician-App
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Generate Model Files

The project uses `json_serializable` for model serialization. Generate the required files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `lib/models/service_model.g.dart`
- `lib/models/appointment_model.g.dart`
- `lib/models/client_model.g.dart`
- `lib/models/business_settings_model.g.dart`

### Step 4: Configure Firebase

Run the FlutterFire CLI to configure Firebase for all platforms:

```bash
flutterfire configure --project=ari-s-esthetician-app
```

This will:
- Register your Flutter app with Firebase
- Generate `lib/core/config/firebase_options.dart` with platform-specific configuration
- Set up iOS, Android, and Web Firebase configurations

**Important**: You need to have:
- Firebase CLI installed and logged in
- Access to the Firebase project: `ari-s-esthetician-app`

### Step 5: Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/project/ari-s-esthetician-app)

2. Enable the following services:
   - **Authentication** (Email/Password provider)
   - **Cloud Firestore** (Start in test mode, then configure rules)
   - **Cloud Functions** (for backend booking validation)
   - **Cloud Storage** (for logo uploads)
   - **Cloud Messaging** (for notifications)

### Step 6: Deploy Firestore Security Rules

Deploy the security rules and indexes:

```bash
firebase deploy --only firestore
```

This deploys:
- `firestore.rules` - Security rules
- `firestore.indexes.json` - Database indexes

### Step 7: Create Admin User

You have three options:

#### Option A: Using the Script (Recommended)

1. Install Firebase Admin SDK:
   ```bash
   npm install firebase-admin
   ```

2. Set service account credentials:
   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\serviceAccountKey.json"
   ```

3. Run the script:
   ```bash
   node scripts/create_admin_user.js admin@example.com yourpassword
   ```

See `scripts/create_admin_user.md` for detailed instructions.

#### Option B: Firebase Console (Manual)

1. Go to [Firebase Console → Authentication](https://console.firebase.google.com/project/ari-s-esthetician-app/authentication/users)
2. Click "Add User"
3. Enter email and password
4. Go to [Firestore Database](https://console.firebase.google.com/project/ari-s-esthetician-app/firestore)
5. Create document in `users` collection:
   - Document ID: `[user-uid-from-auth]`
   - Fields:
     ```json
     {
       "email": "admin@example.com",
       "role": "admin",
       "createdAt": [timestamp],
       "updatedAt": [timestamp]
     }
     ```

#### Option C: Firebase CLI

Use Firebase CLI with custom functions (advanced).

### Step 8: Run the App

```bash
# Run on default device
flutter run

# Run on specific platform
flutter run -d chrome    # Web
flutter run -d ios        # iOS (macOS only)
flutter run -d android    # Android
```

---

## ⚙️ Configuration

### Stripe Setup

1. Create a Stripe account at [stripe.com](https://stripe.com)
2. Get your API keys from the Stripe Dashboard
3. Add Stripe keys to Firestore `business_settings/main` document:
   - `stripePublishableKey`: Your publishable key (safe for client)
   - `stripeSecretKey`: Store in Cloud Functions environment (NOT in client app)

### Google Calendar API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google Calendar API
4. Create service account credentials
5. Download JSON key file
6. Store credentials securely (Cloud Functions environment)
7. Share your Google Calendar with the service account email

### Business Settings Configuration

After logging in as admin, configure your business settings:

1. Navigate to **Admin → Settings**
2. Configure:
   - Business name and contact information
   - Business hours and availability
   - Cancellation and refund policies
   - Stripe API keys
   - Google Calendar integration
   - Email notification settings

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── core/                        # Core functionality
│   ├── config/                  # Firebase, app configuration
│   │   └── firebase_config.dart
│   ├── constants/               # Colors, typography, constants
│   │   ├── app_colors.dart
│   │   ├── app_constants.dart
│   │   └── app_typography.dart
│   ├── logging/                 # Centralized logging
│   │   └── app_logger.dart
│   ├── routing/                 # Navigation and routing
│   │   └── app_router.dart
│   └── theme/                   # App theme
│       └── app_theme.dart
├── models/                      # Data models
│   ├── service_model.dart
│   ├── appointment_model.dart
│   ├── client_model.dart
│   └── business_settings_model.dart
├── screens/                     # UI screens
│   ├── auth/                    # Authentication screens
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── client/                  # Client-facing screens
│   │   ├── client_booking_screen.dart
│   │   └── client_confirmation_screen.dart
│   ├── admin/                   # Admin dashboard screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_services_screen.dart
│   │   ├── admin_appointments_screen.dart
│   │   ├── admin_clients_screen.dart
│   │   └── admin_settings_screen.dart
│   └── splash_screen.dart
└── services/                    # Business logic services
    ├── auth_service.dart
    └── firestore_service.dart
```

---

## 📖 Usage Guide

### For Clients

1. **Browse Services**: Visit the booking page to see available services
2. **Select Service**: Choose a service and view details
3. **Choose Date & Time**: Select from available time slots
4. **Enter Information**: Provide name, email, and phone number
5. **Pay Deposit**: Complete secure payment via Stripe
6. **Confirm Booking**: Receive email confirmation and calendar invite

### For Administrators

1. **Login**: Access admin dashboard with admin credentials
2. **Manage Services**: Add, edit, or deactivate services
3. **View Appointments**: See all appointments in calendar view
4. **Manage Clients**: Search and view client profiles
5. **Configure Settings**: Update business information and integrations

---

## 💻 Development

### Code Generation

When models are updated, regenerate files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or watch for changes:

```bash
flutter pub run build_runner watch
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart
```

### Code Style

The project uses `flutter_lints` for code style. Ensure your IDE is configured to use it.

### Debugging

The app includes a centralized logging system (`AppLogger`). Enable debug logging:

```dart
AppLogger().logInfo('Message', tag: 'Tag');
AppLogger().logError('Error', tag: 'Tag', error: e, stackTrace: stackTrace);
```

---

## 🚢 Deployment

### Web Deployment

1. Build for web:
   ```bash
   flutter build web
   ```

2. Deploy to Firebase Hosting:
   ```bash
   firebase deploy --only hosting
   ```

### iOS Deployment

1. Build iOS app:
   ```bash
   flutter build ios
   ```

2. Open in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

3. Configure signing and deploy to App Store

### Android Deployment

1. Build Android app:
   ```bash
   flutter build appbundle  # For Play Store
   # or
   flutter build apk        # For direct install
   ```

2. Upload to Google Play Console

### Pre-Deployment Checklist

- [ ] Configure Firebase for production
- [ ] Set up Firestore indexes
- [ ] Configure Cloud Functions
- [ ] Set up Stripe webhooks
- [ ] Configure email service
- [ ] Set up Google Calendar service account
- [ ] Test on all platforms
- [ ] Performance testing
- [ ] Security audit
- [ ] App store submissions (iOS/Android)

---

## 🔒 Security

### Security Features

- **Role-Based Access Control**: Admin and client roles with proper permissions
- **Firestore Security Rules**: Comprehensive rules preventing unauthorized access
- **Secure Authentication**: Firebase Authentication with email/password
- **Payment Security**: Stripe handles all payment processing securely
- **API Key Protection**: Secret keys stored in Cloud Functions, not client code

### Security Best Practices

- Never commit API keys or secrets to version control
- Always use Firestore security rules
- Validate all user inputs
- Use HTTPS for all network requests
- Regularly update dependencies
- Monitor Firebase Console for security alerts

---

## 🐛 Troubleshooting

### Common Issues

#### "firebase_options.dart not found"
```bash
flutterfire configure --project=ari-s-esthetician-app
```

#### "Model files missing (.g.dart)"
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### "Permission denied" in Firestore
1. Verify rules are deployed: `firebase deploy --only firestore`
2. Check user role in Firestore `users` collection
3. Verify rules in Firebase Console

#### "Cannot find Firebase"
1. Check Firebase is initialized in `main.dart`
2. Verify `firebase_options.dart` exists
3. Run `flutter clean` and `flutter pub get`

#### Build Errors
```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Getting Help

- Check `TROUBLESHOOTING.md` for detailed solutions
- Review `SETUP.md` for setup instructions
- Check `PROJECT_STATUS.md` for implementation status
- Review Firebase Console for errors

---

## 🤝 Contributing

This is a proprietary project. For contributions or questions, please contact the project maintainer.

---

## 📄 License

Copyright © 2026 Kevin Doyle Jr. / Infinitum Imagery LLC

All rights reserved. This software and associated documentation files (the "Software") are proprietary and confidential. Unauthorized copying, modification, distribution, or use of this Software, via any medium, is strictly prohibited.

---

## 📞 Support

For support, questions, or issues:

- **Email**: [Contact via GitHub Issues](https://github.com/jrftw/Ari-s-Esthetician-App/issues)
- **Documentation**: See project documentation files:
  - `SETUP.md` - Detailed setup instructions
  - `QUICK_START.md` - Quick start guide
  - `PROJECT_STATUS.md` - Current implementation status
  - `TROUBLESHOOTING.md` - Common issues and solutions

---

## 📝 Changelog

### Version 1.0.0 (January 22, 2026)

**Initial Release**
- ✅ Core Flutter project structure
- ✅ Firebase integration (Auth, Firestore, Functions, Storage)
- ✅ Data models (Service, Appointment, Client, BusinessSettings)
- ✅ Authentication service with role management
- ✅ Firestore service with CRUD operations
- ✅ Role-based routing with Go Router
- ✅ Admin dashboard screens (structure)
- ✅ Client booking screens (structure)
- ✅ Sunflower-themed design system
- ✅ Centralized logging system
- ✅ Firestore security rules
- ✅ Stripe payment integration setup
- ✅ Google Calendar API integration setup

**Next Steps**
- Complete client booking flow UI
- Complete admin dashboard UI
- Implement Cloud Functions for booking validation
- Set up email notification service
- Add calendar synchronization
- Implement Stripe webhook handlers

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing framework
- **Firebase Team** - For the robust backend services
- **Stripe** - For secure payment processing
- **Google** - For Calendar API integration

---

**Built with ❤️ by Kevin Doyle Jr. / Infinitum Imagery LLC**
