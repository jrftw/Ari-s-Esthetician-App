/*
 * Filename: main.dart
 * Purpose: Application entry point and initialization
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter, Firebase, Theme, Routing
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'core/routing/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';

// MARK: - Main Function
/// Application entry point
/// Initializes Firebase, logging, and starts the app
void main() async {
  // Basic print to verify app starts (always works)
  print('🔍 ========================================');
  print('🔍 APP STARTING - Main function called');
  print('🔍 ========================================');
  
  try {
    // CRITICAL: Initialize logger FIRST before any logging calls
    print('🔍 Step 1: Initializing logger...');
    AppLogger().initialize();
    print('🔍 Step 1: Logger initialized ✅');
    
    logInit('Starting application initialization', tag: 'Main');
    logStep(1, 'Ensuring Flutter binding is initialized', tag: 'Main');
    
    print('🔍 Step 2: Ensuring Flutter binding...');
    WidgetsFlutterBinding.ensureInitialized();
    print('🔍 Step 2: Flutter binding initialized ✅');
    logSuccess('Flutter binding initialized', tag: 'Main');
  } catch (e, stackTrace) {
    print('🔍 ❌ ERROR in initialization: $e');
    print('🔍 Stack trace: $stackTrace');
    rethrow;
  }

  // Initialize Firebase
  print('🔍 Step 3: Initializing Firebase...');
  logStep(3, 'Initializing Firebase', tag: 'Main');
  bool firebaseInitialized = false;
  String? firebaseError;
  try {
    logFirebase('Attempting Firebase initialization', tag: 'Main');
    await FirebaseConfig.initialize();
    firebaseInitialized = true;
    print('🔍 Step 3: Firebase initialized ✅');
    logSuccess('Firebase initialized successfully', tag: 'Main');
    logComplete('Application initialization complete', tag: 'Main');
  } catch (e, stackTrace) {
    firebaseInitialized = false;
    firebaseError = e.toString();
    print('🔍 Step 3: Firebase failed ❌ - $e');
    logError(
      'Firebase initialization failed',
      tag: 'Main',
      error: e,
      stackTrace: stackTrace,
    );
    logWarning('Continuing with error screen', tag: 'Main');
  }

  print('🔍 Step 4: Building and running app...');
  logStep(4, 'Building and running app', tag: 'Main');
  logUI('Creating ArisEstheticianApp widget', tag: 'Main');
  
  try {
    runApp(ArisEstheticianApp(
      firebaseInitialized: firebaseInitialized,
      firebaseError: firebaseError,
    ));
    print('🔍 Step 4: runApp() called ✅');
    logComplete('App launched successfully', tag: 'Main');
    print('🔍 ========================================');
    print('🔍 APP STARTED SUCCESSFULLY!');
    print('🔍 ========================================');
  } catch (e, stackTrace) {
    print('🔍 ❌ CRITICAL ERROR in runApp: $e');
    print('🔍 Stack trace: $stackTrace');
    // Try to show error widget
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Critical Error: $e'),
        ),
      ),
    ));
  }
}

// MARK: - Main App Widget
/// Root application widget
/// Configures theme, routing, and global app settings
class ArisEstheticianApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? firebaseError;

  const ArisEstheticianApp({
    super.key,
    required this.firebaseInitialized,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    print('🔍 Building ArisEstheticianApp widget...');
    print('🔍 Firebase initialized: $firebaseInitialized');
    
    logUI('Building ArisEstheticianApp widget', tag: 'ArisEstheticianApp');
    logDebug('Firebase initialized: $firebaseInitialized', tag: 'ArisEstheticianApp');
    
    // MARK: - Firebase Error Screen
    /// Show error screen if Firebase failed to initialize
    if (!firebaseInitialized) {
      print('🔍 Firebase not initialized - showing error screen');
      logWarning('Firebase not initialized - showing error screen', tag: 'ArisEstheticianApp');
      logUI('Creating MaterialApp with error screen', tag: 'ArisEstheticianApp');
      return MaterialApp(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _FirebaseErrorScreen(error: firebaseError),
      );
    }

    print('🔍 Creating AppRouter instance...');
    logRouter('Creating AppRouter instance', tag: 'ArisEstheticianApp');
    try {
      final router = AppRouter().router;
      print('🔍 Router created successfully ✅');
      logSuccess('Router created successfully', tag: 'ArisEstheticianApp');

      print('🔍 Creating MaterialApp.router...');
      logUI('Creating MaterialApp.router with theme and routing', tag: 'ArisEstheticianApp');
      final app = MaterialApp.router(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        
        // MARK: - Theme Configuration
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme, // Uncomment when dark mode is implemented
        // themeMode: ThemeMode.system, // Uncomment when dark mode is implemented

        // MARK: - Router Configuration
        routerConfig: router,
      );
      print('🔍 MaterialApp.router created ✅');
      return app;
    } catch (e, stackTrace) {
      print('🔍 ❌ ERROR creating router: $e');
      print('🔍 Stack trace: $stackTrace');
      logError('Failed to create router', tag: 'ArisEstheticianApp', error: e, stackTrace: stackTrace);
      // Fallback to simple MaterialApp if router fails
      return MaterialApp(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _ErrorScreen(
          title: 'Router Error',
          message: 'Failed to initialize router: ${e.toString()}',
        ),
      );
    }
  }
}

// MARK: - Error Screen (Generic)
/// Generic error screen for displaying errors
class _ErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const _ErrorScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    logUI('Building ErrorScreen: $title', tag: 'ErrorScreen');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.darkBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Firebase Error Screen
/// Displays error message when Firebase initialization fails
class _FirebaseErrorScreen extends StatelessWidget {
  final String? error;

  const _FirebaseErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    logUI('Building FirebaseErrorScreen', tag: 'FirebaseErrorScreen');
    logDebug('Error message: ${error ?? "No error details"}', tag: 'FirebaseErrorScreen');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 24),
              Text(
                'Firebase Configuration Error',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.darkBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Firebase has not been properly configured.\n\n'
                'Please run:\n'
                'flutterfire configure --project=ari-s-esthetician-app',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Error: $error',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add error boundary widget
// - Add global loading indicator
// - Add offline mode handling
// - Add app update checking
// - Add analytics initialization
