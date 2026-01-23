/*
 * Filename: version_check_service.dart
 * Purpose: Service for checking app version against latest required version from Firestore
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: cloud_firestore, app_version, app_constants, app_logger
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_version.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';

// MARK: - Version Check Result Model
/// Result of version check operation
class VersionCheckResult {
  /// Whether an update is required
  final bool updateRequired;
  
  /// Current app version
  final String currentVersion;
  
  /// Current build number
  final int currentBuildNumber;
  
  /// Latest required version
  final String? latestVersion;
  
  /// Latest required build number
  final int? latestBuildNumber;
  
  /// Update message from server (optional)
  final String? updateMessage;
  
  /// App Store/Play Store URL (optional)
  final String? updateUrl;
  
  /// Error message if check failed
  final String? error;

  VersionCheckResult({
    required this.updateRequired,
    required this.currentVersion,
    required this.currentBuildNumber,
    this.latestVersion,
    this.latestBuildNumber,
    this.updateMessage,
    this.updateUrl,
    this.error,
  });
}

// MARK: - Version Check Service
/// Service for checking if app version is up to date
/// Fetches latest required version from Firestore and compares with current version
/// Skips check in development mode
class VersionCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // MARK: - Version Check
  /// Check if current app version meets minimum requirements
  /// Returns VersionCheckResult with update status
  /// Always returns updateRequired=false in development mode
  Future<VersionCheckResult> checkVersion() async {
    try {
      logInfo('Starting version check', tag: 'VersionCheckService');
      
      // MARK: - Development Mode Skip
      /// Skip version check in development mode
      if (AppVersion.isDevelopment) {
        logInfo('Development mode detected - skipping version check', tag: 'VersionCheckService');
        return VersionCheckResult(
          updateRequired: false,
          currentVersion: AppVersion.version,
          currentBuildNumber: AppVersion.buildNumber,
          latestVersion: AppVersion.version,
          latestBuildNumber: AppVersion.buildNumber,
        );
      }

      // MARK: - Get Current Version
      /// Get current app version and build number
      final currentVersion = AppVersion.version;
      final currentBuildNumber = AppVersion.buildNumber;
      
      logDebug('Current version: $currentVersion (Build $currentBuildNumber)', tag: 'VersionCheckService');

      // MARK: - Fetch Latest Version from Firestore
      /// Fetch latest required version from Firestore app_version collection
      /// Document ID should be 'latest' or 'current'
      final versionDoc = await _firestore
          .collection(AppConstants.firestoreAppVersionCollection)
          .doc('latest')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logWarning('Version check timeout - allowing app to continue', tag: 'VersionCheckService');
              throw TimeoutException('Version check timed out');
            },
          );

      // MARK: - Handle Missing Version Document
      /// If version document doesn't exist, allow app to continue
      if (!versionDoc.exists) {
        logWarning('Version document not found - allowing app to continue', tag: 'VersionCheckService');
        return VersionCheckResult(
          updateRequired: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          error: 'Version document not found in Firestore',
        );
      }

      // MARK: - Parse Version Data
      /// Extract version and build number from Firestore document
      final versionData = versionDoc.data();
      if (versionData == null) {
        logWarning('Version document has no data - allowing app to continue', tag: 'VersionCheckService');
        return VersionCheckResult(
          updateRequired: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          error: 'Version document has no data',
        );
      }

      final latestVersion = versionData['version'] as String?;
      final latestBuildNumber = versionData['buildNumber'] as int?;
      final updateMessage = versionData['message'] as String?;
      final updateUrl = versionData['updateUrl'] as String?;
      final forceUpdate = versionData['forceUpdate'] as bool? ?? true;

      logDebug('Latest version from Firestore: $latestVersion (Build $latestBuildNumber)', tag: 'VersionCheckService');
      logDebug('Force update enabled: $forceUpdate', tag: 'VersionCheckService');

      // MARK: - Validate Version Data
      /// Ensure we have valid version and build number
      if (latestVersion == null || latestBuildNumber == null) {
        logWarning('Invalid version data in Firestore - allowing app to continue', tag: 'VersionCheckService');
        return VersionCheckResult(
          updateRequired: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          error: 'Invalid version data in Firestore',
        );
      }

      // MARK: - Compare Versions
      /// Compare current version with latest required version
      final versionComparison = AppVersion.compareVersions(currentVersion, latestVersion);
      final buildComparison = currentBuildNumber.compareTo(latestBuildNumber);

      logDebug('Version comparison: $versionComparison (current vs latest)', tag: 'VersionCheckService');
      logDebug('Build comparison: $buildComparison (current vs latest)', tag: 'VersionCheckService');

      // MARK: - Determine Update Requirement
      /// Update required if:
      /// 1. Version is older (versionComparison < 0), OR
      /// 2. Version is same but build is older (versionComparison == 0 && buildComparison < 0)
      final updateRequired = forceUpdate && (
        versionComparison < 0 || 
        (versionComparison == 0 && buildComparison < 0)
      );

      if (updateRequired) {
        logWarning('Update required: Current $currentVersion (Build $currentBuildNumber) < Latest $latestVersion (Build $latestBuildNumber)', tag: 'VersionCheckService');
      } else {
        logInfo('App version is up to date', tag: 'VersionCheckService');
      }

      return VersionCheckResult(
        updateRequired: updateRequired,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
        updateMessage: updateMessage,
        updateUrl: updateUrl,
      );
    } on TimeoutException catch (e) {
      logError('Version check timeout', tag: 'VersionCheckService', error: e);
      // On timeout, allow app to continue (fail open)
      return VersionCheckResult(
        updateRequired: false,
        currentVersion: AppVersion.version,
        currentBuildNumber: AppVersion.buildNumber,
        error: 'Version check timed out',
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to check version',
        tag: 'VersionCheckService',
        error: e,
        stackTrace: stackTrace,
      );
      // On error, allow app to continue (fail open)
      return VersionCheckResult(
        updateRequired: false,
        currentVersion: AppVersion.version,
        currentBuildNumber: AppVersion.buildNumber,
        error: e.toString(),
      );
    }
  }

  // MARK: - Helper Methods
  /// Get version check result synchronously (for testing)
  /// In production, always use checkVersion() async method
  VersionCheckResult getVersionCheckResultSync({
    required bool updateRequired,
    String? error,
  }) {
    return VersionCheckResult(
      updateRequired: updateRequired,
      currentVersion: AppVersion.version,
      currentBuildNumber: AppVersion.buildNumber,
      error: error,
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add version check caching to reduce Firestore reads
// - Implement periodic background version checks
// - Add version check retry logic with exponential backoff
// - Support platform-specific version requirements (iOS vs Android)
// - Add version check analytics tracking
// - Implement graceful degradation when version check fails
// - Add support for optional vs required updates