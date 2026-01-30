/*
 * Filename: firebase_config.dart
 * Purpose: Firebase initialization and configuration
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: firebase_core, firebase_options, firebase_auth (web persistence)
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import '../logging/app_logger.dart';

// MARK: - Firebase Configuration
/// Handles Firebase initialization and configuration
class FirebaseConfig {
  /// Initialize Firebase with platform-specific options
  /// This must be called before using any Firebase services
  /// On web, sets Auth persistence to LOCAL so "Keep Me Signed In" survives refresh and browser close
  static Future<void> initialize() async {
    logFirebase('Starting Firebase initialization', tag: 'FirebaseConfig');
    logDebug('Getting platform-specific Firebase options', tag: 'FirebaseConfig');
    
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      logDebug('Firebase options retrieved for current platform', tag: 'FirebaseConfig');
      logDebug('Project ID: ${options.projectId}', tag: 'FirebaseConfig');
      logDebug('API Key: ${options.apiKey.substring(0, options.apiKey.length > 10 ? 10 : options.apiKey.length)}...', tag: 'FirebaseConfig');
      logDebug('App ID: ${options.appId.substring(0, options.appId.length > 10 ? 10 : options.appId.length)}...', tag: 'FirebaseConfig');
      
      logLoading('Initializing Firebase app...', tag: 'FirebaseConfig');
      await Firebase.initializeApp(
        options: options,
      );
      logSuccess('Firebase initialized successfully', tag: 'FirebaseConfig');

      // MARK: - Auth Persistence (Web)
      // On web, default can be SESSION (cleared on refresh). Set LOCAL so user stays signed in
      // until they explicitly log out when "Keep Me Signed In" is checked.
      if (kIsWeb) {
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
          logSuccess('Firebase Auth persistence set to LOCAL (session survives refresh)', tag: 'FirebaseConfig');
        } catch (persistError, persistStack) {
          logError(
            'Failed to set Auth persistence (non-fatal)',
            tag: 'FirebaseConfig',
            error: persistError,
            stackTrace: persistStack,
          );
        }
      }

      logComplete('Firebase ready to use', tag: 'FirebaseConfig');
    } catch (e, stackTrace) {
      logError(
        'Firebase initialization failed',
        tag: 'FirebaseConfig',
        error: e,
        stackTrace: stackTrace,
      );
      logDebug('Error type: ${e.runtimeType}', tag: 'FirebaseConfig');
      logDebug('Error message: ${e.toString()}', tag: 'FirebaseConfig');
      rethrow;
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add Firebase Analytics initialization
// - Add Firebase Crashlytics setup
// - Add remote config initialization
// - Add performance monitoring
