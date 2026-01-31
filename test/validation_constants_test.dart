/*
 * Filename: validation_constants_test.dart
 * Purpose: Unit tests for validation constants used in guest/directory flow
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: flutter_test, app_constants
 * Platform Compatibility: All
 */

// MARK: - Imports
import 'package:flutter_test/flutter_test.dart';
import 'package:aris_esthetician_app/core/constants/app_constants.dart';

// MARK: - Validation Constants Tests
void main() {
  group('AppConstants validation', () {
    test('minNameLength is at least 1', () {
      expect(AppConstants.minNameLength, greaterThanOrEqualTo(1));
    });
    test('minPhoneLength is at least 10', () {
      expect(AppConstants.minPhoneLength, greaterThanOrEqualTo(10));
    });
    test('maxNameLength is reasonable', () {
      expect(AppConstants.maxNameLength, greaterThanOrEqualTo(AppConstants.minNameLength));
    });
    test('maxPhoneLength is reasonable', () {
      expect(AppConstants.maxPhoneLength, greaterThanOrEqualTo(AppConstants.minPhoneLength));
    });
  });
}
