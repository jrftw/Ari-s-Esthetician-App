# Global Debug Logger Guide

## Overview

The app now includes a comprehensive emoji-based debug logging system that **only displays in development mode** (`kDebugMode`). This logger automatically disables itself in release builds for security and performance.

## Features

✅ **Emoji-based visual indicators** for easy log scanning  
✅ **Development-only** - automatically disabled in release builds  
✅ **Detailed step-by-step tracking** of app initialization  
✅ **Widget lifecycle tracking**  
✅ **Specialized logging** for Firebase, Router, Auth, Database, UI  
✅ **Error tracking** with full stack traces  

## Emoji Legend

| Emoji | Meaning | Usage |
|-------|---------|-------|
| ✅ | Success | Operation completed successfully |
| ❌ | Error | Error occurred |
| ⚠️ | Warning | Warning message |
| ℹ️ | Info | Informational message |
| 🐛 | Debug | Debug information |
| 🔥 | Firebase | Firebase operations |
| 🧭 | Router | Navigation/routing |
| 🔐 | Auth | Authentication |
| 💾 | Database | Database operations |
| 🌐 | Network | Network operations |
| 🎨 | UI | UI/widget operations |
| 🚀 | Init | Initialization |
| ⏳ | Loading | Loading state |
| ✨ | Complete | Process completed |
| ▶️ | Start | Process started |
| ⏹️ | Stop | Process stopped |
| ✔️ | Check | Verification |
| ✖️ | Cross | Failed check |
| ➡️ | Arrow | Step/process step |
| ⭐ | Star | Important note |
| ⚙️ | Gear | Configuration |
| 🔒 | Lock | Security |
| 🔓 | Unlock | Access granted |
| 👤 | User | User operation |
| 👑 | Admin | Admin operation |
| 💼 | Client | Client operation |

## Usage Examples

### Basic Logging

```dart
// Info logging
logInfo('User logged in', tag: 'AuthService');

// Debug logging
logDebug('Processing payment', tag: 'PaymentService');

// Error logging
logError('Failed to load data', tag: 'DataService', error: e, stackTrace: stackTrace);

// Warning logging
logWarning('Network request took longer than expected', tag: 'NetworkService');

// Success logging
logSuccess('Data saved successfully', tag: 'DataService');
```

### Specialized Logging

```dart
// Firebase operations
logFirebase('Initializing Firebase', tag: 'FirebaseConfig');
logFirebase('Firebase initialized', tag: 'FirebaseConfig');

// Router operations
logRouter('Navigating to /booking', tag: 'AppRouter');
logRouter('Route built successfully', tag: 'AppRouter');

// Authentication
logAuth('User signed in', tag: 'AuthService');
logAuth('Checking admin status', tag: 'AuthService');

// Database
logDatabase('Saving appointment', tag: 'FirestoreService');
logDatabase('Appointment saved', tag: 'FirestoreService');

// UI operations
logUI('Building widget', tag: 'BookingScreen');
logUI('Widget built', tag: 'BookingScreen');

// Initialization
logInit('Starting app initialization', tag: 'Main');
logInit('App initialized', tag: 'Main');

// Step-by-step tracking
logStep(1, 'Loading user data', tag: 'UserService');
logStep(2, 'Validating data', tag: 'UserService');
logStep(3, 'Saving to database', tag: 'UserService');
```

### Widget Lifecycle Tracking

```dart
@override
void initState() {
  super.initState();
  logWidgetLifecycle('MyWidget', 'initState', tag: 'MyWidget');
}

@override
Widget build(BuildContext context) {
  logWidgetLifecycle('MyWidget', 'build', tag: 'MyWidget');
  return Container();
}
```

## What Gets Logged

The logger automatically tracks:

1. **App Initialization**
   - Flutter binding initialization
   - Logger setup
   - Firebase initialization
   - Router creation
   - Widget building

2. **Navigation**
   - Route changes
   - Redirect logic
   - Route building
   - Navigation decisions

3. **Authentication**
   - User login/logout
   - Role checks
   - Auth state changes

4. **Widget Lifecycle**
   - initState calls
   - build calls
   - Widget creation

5. **Errors**
   - Full error messages
   - Stack traces
   - Error context

## Viewing Logs

### In Development

Logs appear in:
- **Terminal/Console** where you run `flutter run`
- **Browser Console** (F12) when running on web
- **VS Code/Android Studio** debug console

### Log Format

```
🐛 [Tag] Message
   Error details (if any)
   Stack trace (if any)
   Timestamp
```

## Disabling Logs

Logs are **automatically disabled** in release builds. The logger checks `kDebugMode`:

```dart
const bool ENABLE_DEBUG_LOGGING = kDebugMode; // false in release
```

To manually disable in development (not recommended):

```dart
// In app_logger.dart
const bool ENABLE_DEBUG_LOGGING = false;
```

## Debugging White Screen Issues

The logger now tracks:

1. ✅ App initialization steps
2. ✅ Firebase configuration
3. ✅ Router creation
4. ✅ Route navigation
5. ✅ Widget building
6. ✅ Error details

**Check your terminal/console** when the app starts to see exactly where it's getting stuck!

## Best Practices

1. **Use appropriate tags** - Makes logs easier to filter
2. **Log important steps** - Especially in initialization
3. **Include context** - Add relevant data to log messages
4. **Use specialized loggers** - Use `logFirebase`, `logRouter`, etc. for better categorization
5. **Don't log sensitive data** - Never log passwords, tokens, etc.

## Example Output

```
🚀 [Main] Starting application initialization
➡️ Step 1 [Main]: Ensuring Flutter binding is initialized
✅ [Main] Flutter binding initialized
➡️ Step 2 [Main]: Initializing logger
🐛 [AppLogger] Logger initialized in DEBUG mode
✅ [Main] Logger initialized
➡️ Step 3 [Main]: Initializing Firebase
🔥 [FirebaseConfig] Starting Firebase initialization
🐛 [FirebaseConfig] Getting platform-specific Firebase options
🔥 [FirebaseConfig] Firebase initialized successfully
✅ [Main] Firebase initialized successfully
✨ [Main] Application initialization complete
➡️ Step 4 [Main]: Building and running app
🎨 [ArisEstheticianApp] Building ArisEstheticianApp widget
🧭 [AppRouter] Creating GoRouter instance
✅ [AppRouter] Router created successfully
🎨 [ArisEstheticianApp] Creating MaterialApp.router with theme and routing
✨ [Main] App launched successfully
```

This detailed logging will help you identify exactly where the white screen issue is occurring!
