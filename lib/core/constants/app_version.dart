/*
 * Filename: app_version.dart
 * Purpose: Global version and build number management with environment-based display
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: package_info_plus (for getting package info)
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:package_info_plus/package_info_plus.dart';

// MARK: - App Environment Enum
/// Application environment types
enum AppEnvironment {
  /// Development environment - shows "dev" in version string
  development,
  
  /// Beta/Staging environment - shows "beta" in version string
  beta,
  
  /// Production environment - no suffix shown
  production,
}

// MARK: - App Version Class
/// Centralized version and build number management
/// Provides version information with environment-based display
class AppVersion {
  AppVersion._(); // Private constructor to prevent instantiation

  // MARK: - Version Constants
  /// Application version number (major.minor.patch)
  static const String version = "1.0.0";
  
  /// Build number (incremented with each build)
  static const int buildNumber = 2;
  
  /// Current app environment
  /// Change this to switch between dev, beta, and production
  static const AppEnvironment environment = AppEnvironment.development;

  // MARK: - Version String Getters
  /// Get full version string with environment suffix
  /// Format: "1.0.0 (Build 1) [dev]" for dev
  /// Format: "1.0.0 (Build 1) [beta]" for beta
  /// Format: "1.0.0 (Build 1)" for production
  static String get versionString {
    final baseVersion = "$version (Build $buildNumber)";
    
    switch (environment) {
      case AppEnvironment.development:
        return "$baseVersion [dev]";
      case AppEnvironment.beta:
        return "$baseVersion [beta]";
      case AppEnvironment.production:
        return baseVersion;
    }
  }

  /// Get version string without build number
  /// Format: "1.0.0 [dev]" for dev
  /// Format: "1.0.0 [beta]" for beta
  /// Format: "1.0.0" for production
  static String get versionStringShort {
    switch (environment) {
      case AppEnvironment.development:
        return "$version [dev]";
      case AppEnvironment.beta:
        return "$version [beta]";
      case AppEnvironment.production:
        return version;
    }
  }

  /// Get build number as string
  static String get buildNumberString => buildNumber.toString();

  /// Get environment name as string
  static String get environmentString {
    switch (environment) {
      case AppEnvironment.development:
        return "dev";
      case AppEnvironment.beta:
        return "beta";
      case AppEnvironment.production:
        return "production";
    }
  }

  // MARK: - Package Info Integration
  /// Get version from package info (async)
  /// This reads from pubspec.yaml version field
  static Future<String> getPackageVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return version; // Fallback to constant
    }
  }

  /// Get build number from package info (async)
  /// This reads from pubspec.yaml build number
  static Future<String> getPackageBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      return buildNumberString; // Fallback to constant
    }
  }

  /// Get full version info from package (async)
  /// Returns: "version+buildNumber"
  static Future<String> getPackageVersionFull() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return "${packageInfo.version}+${packageInfo.buildNumber}";
    } catch (e) {
      return "$version+$buildNumber"; // Fallback to constants
    }
  }

  // MARK: - Environment Checks
  /// Check if running in development environment
  static bool get isDevelopment => environment == AppEnvironment.development;

  /// Check if running in beta environment
  static bool get isBeta => environment == AppEnvironment.beta;

  /// Check if running in production environment
  static bool get isProduction => environment == AppEnvironment.production;

  /// Check if running in non-production environment
  static bool get isNonProduction => !isProduction;

  // MARK: - Version Comparison
  /// Compare version strings
  /// Returns: -1 if this < other, 0 if equal, 1 if this > other
  static int compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    // Pad shorter version with zeros
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);
    
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    return 0;
  }

  // MARK: - Display Helpers
  /// Get version display text for UI
  /// Shows environment badge for non-production
  static String getDisplayText({bool showBuildNumber = true}) {
    if (showBuildNumber) {
      return versionString;
    } else {
      return versionStringShort;
    }
  }

  /// Get version info for about screen or settings
  /// Returns formatted string with all version details
  static String getAboutText() {
    return '''
Version: $version
Build: $buildNumber
Environment: ${environmentString.toUpperCase()}
''';
  }
}

// Suggestions For Features and Additions Later:
// - Add version history tracking
// - Implement automatic build number incrementing
// - Add version update checking
// - Implement feature flags based on version
// - Add version migration helpers
// - Consider adding semantic versioning validation
