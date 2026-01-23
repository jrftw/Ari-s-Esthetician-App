/*
 * Filename: firebase_config.dart
 * Purpose: Firebase initialization and configuration
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: firebase_core, firebase_options
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '../logging/app_logger.dart';

// MARK: - Firebase Configuration
/// Handles Firebase initialization and configuration
class FirebaseConfig {
  /// Initialize Firebase with platform-specific options
  /// This must be called before using any Firebase services
  static Future<void> initialize() async {
    logFirebase('Starting Firebase initialization', tag: 'FirebaseConfig');
    logDebug('Getting platform-specific Firebase options', tag: 'FirebaseConfig');
    
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      logDebug('Firebase options retrieved for current platform', tag: 'FirebaseConfig');
      logDebug('Project ID: ${options.projectId}', tag: 'FirebaseConfig');
      logDebug('API Key: ${options.apiKey?.substring(0, 10) ?? "null"}...', tag: 'FirebaseConfig');
      logDebug('App ID: ${options.appId?.substring(0, 10) ?? "null"}...', tag: 'FirebaseConfig');
      
      logLoading('Initializing Firebase app...', tag: 'FirebaseConfig');
      await Firebase.initializeApp(
        options: options,
      );
      logSuccess('Firebase initialized successfully', tag: 'FirebaseConfig');
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
