/*
 * Filename: app_diagnostics_service.dart
 * Purpose: Global diagnostics for when things are not working; produces user-safe,
 *          copyable reports (no code, PII, or private details) for support.
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Flutter foundation (optional), app_logger
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/foundation.dart' show kDebugMode;
import '../core/logging/app_logger.dart';

// MARK: - Diagnostic Check Names (User-Facing Only)
/// Display names for diagnostic checks. Used in reports only; no internal identifiers exposed.
class AriDiagnosticCheckNames {
  AriDiagnosticCheckNames._();
  static const String firebase = 'Firebase';
  static const String appRouter = 'App navigation';
  static const String versionCheck = 'Version check';
  static const String authentication = 'Authentication';
  static const String database = 'Database connection';
}

// MARK: - Single Check Result
/// Result of one diagnostic check. Status and optional short, user-safe reason only.
class AriDiagnosticCheckResult {
  final String displayName;
  final bool working;
  /// Short, user-safe reason when not working (e.g. "Initialization failed"). No code or paths.
  final String? shortReason;

  const AriDiagnosticCheckResult({
    required this.displayName,
    required this.working,
    this.shortReason,
  });
}

// MARK: - App Diagnostics Service
/// Central service for recording and exporting diagnostics only when something is not working.
/// Reports are safe to share: no code, stack traces, API keys, or private information.
class AppDiagnosticsService {
  static final AppDiagnosticsService _instance = AppDiagnosticsService._internal();
  factory AppDiagnosticsService() => _instance;
  AppDiagnosticsService._internal();

  final Map<String, AriDiagnosticCheckResult> _results = {};
  static const String _appDisplayName = "Ari's Esthetician App";

  // MARK: - Recording
  /// Record a check result. [checkKey] is internal (e.g. 'firebase'); [displayName] is for the report.
  void recordCheck({
    required String checkKey,
    required String displayName,
    required bool working,
    String? shortReason,
  }) {
    _results[checkKey] = AriDiagnosticCheckResult(
      displayName: displayName,
      working: working,
      shortReason: working ? null : shortReason,
    );
    if (kDebugMode) {
      AppLogger().logDebug(
        'Diagnostics: $displayName = ${working ? "working" : "not working"}${shortReason != null ? " ($shortReason)" : ""}',
        tag: 'AppDiagnosticsService',
      );
    }
  }

  /// Record that a check was not performed (e.g. dependency failed).
  void recordUnavailable({
    required String checkKey,
    required String displayName,
    String? reason,
  }) {
    _results[checkKey] = AriDiagnosticCheckResult(
      displayName: displayName,
      working: false,
      shortReason: reason ?? 'Unavailable',
    );
  }

  // MARK: - Query
  /// True if any recorded check is not working.
  bool get hasAnyFailure {
    return _results.values.any((r) => !r.working);
  }

  /// Get all results in insertion order (report order). Keys not used in output.
  List<AriDiagnosticCheckResult> get _orderedResults => _results.values.toList();

  // MARK: - Report Generation
  /// Generates a copyable, user-safe report. Returns empty string when everything is working.
  /// Use this only when [hasAnyFailure] is true so users copy reports only when needed.
  String getCopyableReport() {
    if (!hasAnyFailure) return '';

    final buffer = StringBuffer();
    buffer.writeln('$_appDisplayName — Diagnostic Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Use this only when something is not working. Send to support for help.');
    buffer.writeln('');

    final working = _orderedResults.where((r) => r.working).toList();
    final notWorking = _orderedResults.where((r) => !r.working).toList();

    if (working.isNotEmpty) {
      buffer.writeln('Working:');
      for (final r in working) {
        buffer.writeln('  - ${r.displayName}');
      }
      buffer.writeln('');
    }

    if (notWorking.isNotEmpty) {
      buffer.writeln('Not working:');
      for (final r in notWorking) {
        final reason = r.shortReason != null ? ': ${r.shortReason}' : '';
        buffer.writeln('  - ${r.displayName}$reason');
      }
      buffer.writeln('');
    }

    buffer.writeln('(No code, account details, or private information is included.)');
    return buffer.toString();
  }

  /// Clear all recorded results (e.g. after app restart simulation). Used only if needed.
  void clear() {
    _results.clear();
  }
}

// Suggestions For Features and Additions Later:
// - Optional: run lightweight auth/database checks when Firebase is up and include in report
// - Optional: add platform (iOS/Android/Web) and app version line to report for support
// - Optional: rate-limit how often report can be copied to avoid abuse
