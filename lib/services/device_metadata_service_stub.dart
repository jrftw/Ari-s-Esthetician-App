/*
 * Filename: device_metadata_service_stub.dart
 * Purpose: Stub implementation for device metadata (fallback)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: None
 * Platform Compatibility: All (fallback)
 */

// MARK: - Stub Implementation
String getPlatformImpl() => 'Unknown';
Future<String> getOSVersionImpl() async => 'Unknown';
Future<String> getUserAgentImpl() async => 'Unknown';
