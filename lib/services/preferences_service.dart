/*
 * Filename: preferences_service.dart
 * Purpose: Service for managing local preferences and user settings storage
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: shared_preferences, Flutter foundation (ChangeNotifier)
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/logging/app_logger.dart';

// MARK: - Theme and Aura Constants
/// Stored theme mode: "light" | "dark" | "system"
const String kThemeModeLight = 'light';
const String kThemeModeDark = 'dark';
const String kThemeModeSystem = 'system';

/// Stored aura intensity: "low" | "medium" | "high"
const String kAuraIntensityLow = 'low';
const String kAuraIntensityMedium = 'medium';
const String kAuraIntensityHigh = 'high';

// MARK: - Preferences Service
/// Service for managing local user preferences
/// Handles storage and retrieval of user settings like login, theme, and aura
/// Notifies listeners when theme or aura settings change so UI can rebuild
class PreferencesService extends ChangeNotifier {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyKeepSignedIn = 'keep_signed_in';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAuraEnabled = 'aura_enabled';
  static const String _keyAuraIntensity = 'aura_intensity';

  // MARK: - Singleton Pattern
  static PreferencesService? _instance;
  static PreferencesService get instance {
    _instance ??= PreferencesService._();
    return _instance!;
  }

  PreferencesService._();

  // MARK: - Theme and Aura Cache (sync after ensureCache)
  bool _themeAuraCacheLoaded = false;
  String _cachedThemeMode = kThemeModeSystem;
  bool _cachedAuraEnabled = true;
  String _cachedAuraIntensity = kAuraIntensityMedium;

  /// Load theme and aura prefs from disk; call once at app start (e.g. main app initState)
  Future<void> ensureThemeAuraCache() async {
    if (_themeAuraCacheLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedThemeMode = prefs.getString(_keyThemeMode) ?? kThemeModeSystem;
      _cachedAuraEnabled = prefs.getBool(_keyAuraEnabled) ?? true;
      _cachedAuraIntensity = prefs.getString(_keyAuraIntensity) ?? kAuraIntensityMedium;
      _themeAuraCacheLoaded = true;
      AppLogger().logInfo('Theme/aura cache loaded: mode=$_cachedThemeMode aura=$_cachedAuraEnabled intensity=$_cachedAuraIntensity', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError('Failed to load theme/aura cache', tag: 'PreferencesService', error: e, stackTrace: stackTrace);
    }
  }

  /// Current theme mode (sync, use after ensureThemeAuraCache)
  String get themeModeSync => _cachedThemeMode;
  bool get auraEnabledSync => _cachedAuraEnabled;
  String get auraIntensitySync => _cachedAuraIntensity;

  /// Set theme mode and persist; notifies listeners
  Future<void> setThemeMode(String value) async {
    if (_cachedThemeMode == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, value);
      _cachedThemeMode = value;
      notifyListeners();
      AppLogger().logInfo('Theme mode saved: $value', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError('Failed to save theme mode', tag: 'PreferencesService', error: e, stackTrace: stackTrace);
    }
  }

  /// Set aura enabled and persist; notifies listeners
  Future<void> setAuraEnabled(bool value) async {
    if (_cachedAuraEnabled == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAuraEnabled, value);
      _cachedAuraEnabled = value;
      notifyListeners();
      AppLogger().logInfo('Aura enabled saved: $value', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError('Failed to save aura enabled', tag: 'PreferencesService', error: e, stackTrace: stackTrace);
    }
  }

  /// Set aura intensity and persist; notifies listeners
  Future<void> setAuraIntensity(String value) async {
    if (_cachedAuraIntensity == value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuraIntensity, value);
      _cachedAuraIntensity = value;
      notifyListeners();
      AppLogger().logInfo('Aura intensity saved: $value', tag: 'PreferencesService');
    } catch (e, stackTrace) {
      AppLogger().logError('Failed to save aura intensity', tag: 'PreferencesService', error: e, stackTrace: stackTrace);
    }
  }

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
