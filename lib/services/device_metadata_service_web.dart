/*
 * Filename: device_metadata_service_web.dart
 * Purpose: Web-specific implementation for device metadata service
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: dart:html
 * Platform Compatibility: Web only
 */

// MARK: - Imports
import 'dart:html' as html;

// MARK: - Web Implementation
String getPlatformImpl() {
  return 'Web';
}

Future<String> getOSVersionImpl() async {
  try {
    // Try to extract OS from user agent
    final userAgent = html.window.navigator.userAgent;
    if (userAgent.contains('Windows')) {
      return 'Windows';
    } else if (userAgent.contains('Mac')) {
      return 'macOS';
    } else if (userAgent.contains('Linux')) {
      return 'Linux';
    } else if (userAgent.contains('Android')) {
      return 'Android';
    } else if (userAgent.contains('iOS') || userAgent.contains('iPhone') || userAgent.contains('iPad')) {
      return 'iOS';
    } else {
      return 'Unknown';
    }
  } catch (e) {
    return 'Unknown';
  }
}

Future<String> getUserAgentImpl() async {
  try {
    return html.window.navigator.userAgent;
  } catch (e) {
    return 'Unknown';
  }
}

// Suggestions For Features and Additions Later:
// - Add WebRTC-based IP detection (requires user permission)
// - Add third-party IP lookup service integration
// - Add browser fingerprinting for enhanced tracking
