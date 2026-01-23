/*
 * Filename: device_metadata_service_io.dart
 * Purpose: IO (mobile/desktop) implementation for device metadata service
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: dart:io, package_info_plus
 * Platform Compatibility: iOS, Android, Windows, macOS, Linux
 */

// MARK: - Imports
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';

// MARK: - IO Implementation
String getPlatformImpl() {
  if (Platform.isIOS) {
    return 'iOS';
  } else if (Platform.isAndroid) {
    return 'Android';
  } else if (Platform.isWindows) {
    return 'Windows';
  } else if (Platform.isMacOS) {
    return 'macOS';
  } else if (Platform.isLinux) {
    return 'Linux';
  } else {
    return 'Unknown';
  }
}

Future<String> getOSVersionImpl() async {
  return Platform.operatingSystemVersion;
}

Future<String> getUserAgentImpl() async {
  final platform = getPlatformImpl();
  final osVersion = await getOSVersionImpl();
  final packageInfo = await PackageInfo.fromPlatform();
  return '$platform $osVersion / ${packageInfo.appName} ${packageInfo.version}';
}
