/*
 * Filename: app_logger.dart
 * Purpose: Centralized logging system with emoji-based visual debugging (development only)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: logger package, flutter/foundation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

// MARK: - Global Configuration
/// Global flag to enable/disable debug logging across the entire app
/// Only active in debug mode (kDebugMode)
const bool ENABLE_DEBUG_LOGGING = kDebugMode; // Automatically false in release builds

// MARK: - Emoji Constants
/// Emoji-based visual indicators for different log types
class DebugEmojis {
  static const String success = '✅';
  static const String error = '❌';
  static const String warning = '⚠️';
  static const String info = 'ℹ️';
  static const String debug = '🐛';
  static const String firebase = '🔥';
  static const String router = '🧭';
  static const String auth = '🔐';
  static const String database = '💾';
  static const String network = '🌐';
  static const String ui = '🎨';
  static const String init = '🚀';
  static const String loading = '⏳';
  static const String complete = '✨';
  static const String start = '▶️';
  static const String stop = '⏹️';
  static const String check = '✔️';
  static const String cross = '✖️';
  static const String arrow = '➡️';
  static const String star = '⭐';
  static const String rocket = '🚀';
  static const String bug = '🐛';
  static const String gear = '⚙️';
  static const String lock = '🔒';
  static const String unlock = '🔓';
  static const String user = '👤';
  static const String admin = '👑';
  static const String client = '💼';
}

// MARK: - Logger Instance
/// Singleton logger instance for the application
/// Enhanced with emoji-based visual debugging for development
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;
  bool _initialized = false;

  /// Initialize the logger with enhanced configuration
  void initialize() {
    if (_initialized) return;
    
    _logger = Logger(
      level: ENABLE_DEBUG_LOGGING ? Level.debug : Level.warning,
      printer: PrettyPrinter(
        methodCount: 3,
        errorMethodCount: 10,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
        noBoxingByDefault: false,
      ),
    );
    
    _initialized = true;
    
    if (ENABLE_DEBUG_LOGGING) {
      _logger.d('${DebugEmojis.init} Logger initialized in DEBUG mode');
      _logger.d('${DebugEmojis.gear} Debug logging: ${ENABLE_DEBUG_LOGGING ? "ENABLED" : "DISABLED"}');
    }
  }

  // MARK: - Enhanced Logging Methods with Emojis
  /// Log informational messages with info emoji
  void logInfo(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.info;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.i(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log debug messages with debug emoji
  void logDebug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.debug;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.d(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log error messages with error emoji
  void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final emoji = DebugEmojis.error;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.e(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages with warning emoji
  void logWarning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final emoji = DebugEmojis.warning;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.w(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log success messages with success emoji
  void logSuccess(String message, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.success;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.i(taggedMessage);
  }

  // MARK: - Specialized Logging Methods
  /// Log Firebase-related operations
  void logFirebase(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.firebase;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.d(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log routing operations
  void logRouter(String message, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.router;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.d(taggedMessage);
  }

  /// Log authentication operations
  void logAuth(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.auth;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.d(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log database operations
  void logDatabase(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.database;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.d(taggedMessage, error: error, stackTrace: stackTrace);
  }

  /// Log UI operations
  void logUI(String message, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.ui;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.d(taggedMessage);
  }

  /// Log initialization steps
  void logInit(String message, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.init;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.i(taggedMessage);
  }

  /// Log loading states
  void logLoading(String message, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.loading;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.d(taggedMessage);
  }

  /// Log completion states
  void logComplete(String message, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.complete;
    final taggedMessage = tag != null ? '$emoji [$tag] $message' : '$emoji $message';
    _logger.i(taggedMessage);
  }

  /// Log step-by-step process tracking
  void logStep(int step, String message, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.arrow;
    final taggedMessage = tag != null 
        ? '$emoji Step $step [$tag]: $message' 
        : '$emoji Step $step: $message';
    _logger.d(taggedMessage);
  }

  /// Log widget lifecycle events
  void logWidgetLifecycle(String widgetName, String event, {String? tag}) {
    if (!ENABLE_DEBUG_LOGGING) return;
    final emoji = DebugEmojis.ui;
    final message = '$emoji Widget [$widgetName] $event';
    _logger.d(message);
  }
}

// MARK: - Global Helper Functions
/// Global helper for info logging
void logInfo(String message, {String? tag}) {
  AppLogger().logInfo(message, tag: tag);
}

/// Global helper for debug logging
void logDebug(String message, {String? tag}) {
  AppLogger().logDebug(message, tag: tag);
}

/// Global helper for error logging
void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
  AppLogger().logError(message, tag: tag, error: error, stackTrace: stackTrace);
}

/// Global helper for warning logging
void logWarning(String message, {String? tag}) {
  AppLogger().logWarning(message, tag: tag);
}

/// Global helper for success logging
void logSuccess(String message, {String? tag}) {
  AppLogger().logSuccess(message, tag: tag);
}

/// Global helper for Firebase logging
void logFirebase(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
  AppLogger().logFirebase(message, tag: tag, error: error, stackTrace: stackTrace);
}

/// Global helper for router logging
void logRouter(String message, {String? tag}) {
  AppLogger().logRouter(message, tag: tag);
}

/// Global helper for auth logging
void logAuth(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
  AppLogger().logAuth(message, tag: tag, error: error, stackTrace: stackTrace);
}

/// Global helper for database logging
void logDatabase(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
  AppLogger().logDatabase(message, tag: tag, error: error, stackTrace: stackTrace);
}

/// Global helper for UI logging
void logUI(String message, {String? tag}) {
  AppLogger().logUI(message, tag: tag);
}

/// Global helper for initialization logging
void logInit(String message, {String? tag}) {
  AppLogger().logInit(message, tag: tag);
}

/// Global helper for step-by-step process logging
void logStep(int step, String message, {String? tag}) {
  AppLogger().logStep(step, message, tag: tag);
}

/// Global helper for loading state logging
void logLoading(String message, {String? tag}) {
  AppLogger().logLoading(message, tag: tag);
}

/// Global helper for completion logging
void logComplete(String message, {String? tag}) {
  AppLogger().logComplete(message, tag: tag);
}

/// Global helper for widget lifecycle logging
void logWidgetLifecycle(String widgetName, String event, {String? tag}) {
  AppLogger().logWidgetLifecycle(widgetName, event, tag: tag);
}

// Suggestions For Features and Additions Later:
// - Add remote logging configuration (Firebase Crashlytics)
// - Implement log levels per module
// - Add log export functionality for debugging
// - Consider adding analytics event tracking integration
