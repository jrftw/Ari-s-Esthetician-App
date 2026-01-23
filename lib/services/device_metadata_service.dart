/*
 * Filename: device_metadata_service.dart
 * Purpose: Service for capturing device metadata for legal compliance (IP, user agent, platform info)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: package_info_plus
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:package_info_plus/package_info_plus.dart';
import 'device_metadata_service_stub.dart'
    if (dart.library.io) 'device_metadata_service_io.dart'
    if (dart.library.html) 'device_metadata_service_web.dart';

// MARK: - Device Metadata Service
/// Service for capturing device and session metadata
/// Used for legal compliance and audit trails
class DeviceMetadataService {
  DeviceMetadataService._(); // Private constructor to prevent instantiation

  // MARK: - Device Information
  /// Get platform name (iOS, Android, Web, etc.)
  static String getPlatform() {
    return getPlatformImpl();
  }

  /// Get operating system version
  static Future<String> getOSVersion() async {
    return await getOSVersionImpl();
  }

  /// Get user agent string
  /// Returns user agent for web, or device info for mobile
  static Future<String> getUserAgent() async {
    return await getUserAgentImpl();
  }

  /// Get IP address (best-effort)
  /// Note: Client-side IP capture is limited. For accurate IP, capture on backend.
  /// This method returns null - IP should be captured server-side during booking submission.
  static Future<String?> getIPAddress() async {
    // Browser and mobile security restrictions prevent direct IP capture
    // IP address should be captured server-side (Firebase Functions) during booking submission
    return null;
  }

  /// Get complete device metadata for legal compliance
  static Future<Map<String, String?>> getDeviceMetadata() async {
    final platform = getPlatform();
    final osVersion = await getOSVersion();
    final userAgent = await getUserAgent();
    final ipAddress = await getIPAddress();

    return {
      'platform': platform,
      'osVersion': osVersion,
      'userAgent': userAgent,
      'ipAddress': ipAddress,
    };
  }
}

// Suggestions For Features and Additions Later:
// - Add device fingerprinting for enhanced security
// - Add geolocation capture (with user consent)
// - Add network type detection (WiFi, cellular, etc.)
// - Add screen resolution and device model
// - Add app version and build number tracking
