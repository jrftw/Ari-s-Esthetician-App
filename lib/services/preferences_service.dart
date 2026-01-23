/*
 * Filename: preferences_service.dart
 * Purpose: Service for managing local preferences and user settings storage
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: shared_preferences
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:shared_preferences/shared_preferences.dart';
import '../core/logging/app_logger.dart';

// MARK: - Preferences Service
/// Service for managing local user preferences
/// Handles storage and retrieval of user settings like login preferences
/// 
/// Note: SharedPreferences persists across app updates and versions.
/// The "keep_signed_in" preference will persist even when the app is updated,
/// ensuring users remain signed in across new app versions.
class PreferencesService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyKeepSignedIn = 'keep_signed_in';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  // MARK: - Singleton Pattern
  static PreferencesService? _instance;
  static PreferencesService get instance {
    _instance ??= PreferencesService._();
    return _instance!;
  }

  PreferencesService._();

  // MARK: - Remember Me Preferences
  /// Save remember me preference
  Future<void> setRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, value);
      AppLogger().logInfo('Remember me preference saved: $value', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to save remember me preference',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get remember me preference
  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get remember me preference',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // MARK: - Keep Signed In Preferences
  /// Save keep signed in preference
  Future<void> setKeepSignedIn(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyKeepSignedIn, value);
      AppLogger().logInfo('Keep signed in preference saved: $value', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to save keep signed in preference',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get keep signed in preference
  Future<bool> getKeepSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyKeepSignedIn) ?? false;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get keep signed in preference',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // MARK: - Saved Email
  /// Save email for remember me functionality
  Future<void> saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySavedEmail, email);
      AppLogger().logInfo('Email saved for remember me', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to save email',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get saved email
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySavedEmail);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get saved email',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clear saved email
  Future<void> clearSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySavedEmail);
      AppLogger().logInfo('Saved email cleared', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to clear saved email',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // MARK: - Saved Password (Optional - for Remember Me)
  /// Save password for remember me functionality (optional, less secure)
  /// Note: Storing passwords is generally not recommended, but provided for user convenience
  Future<void> savePassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySavedPassword, password);
      AppLogger().logInfo('Password saved for remember me', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to save password',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get saved password
  Future<String?> getSavedPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySavedPassword);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get saved password',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Clear saved password
  Future<void> clearSavedPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySavedPassword);
      AppLogger().logInfo('Saved password cleared', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to clear saved password',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // MARK: - Clear All Login Preferences
  /// Clear all login-related preferences
  Future<void> clearLoginPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyKeepSignedIn);
      await prefs.remove(_keySavedEmail);
      await prefs.remove(_keySavedPassword);
      AppLogger().logInfo('All login preferences cleared', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to clear login preferences',
        tag: 'PreferencesService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add encryption for sensitive stored data
// - Add preference sync across devices
// - Add preference export/import functionality
// - Add preference categories and organization
// - Add preference validation and migration
