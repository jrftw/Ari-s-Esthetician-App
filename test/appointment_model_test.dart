/*
 * Filename: appointment_model_test.dart
 * Purpose: Unit tests for AppointmentModel mapping and new compliance fields
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: flutter_test, appointment_model
 * Platform Compatibility: All
 */

// MARK: - Imports
import 'package:flutter_test/flutter_test.dart';
import 'package:aris_esthetician_app/models/appointment_model.dart';
import 'package:aris_esthetician_app/models/service_model.dart';

// MARK: - Appointment Model Tests
void main() {
  group('AppointmentModel', () {
    test('fromJson/toJson round-trip with new optional fields', () {
      final now = DateTime.now();
      final json = {
        'id': 'apt1',
        'serviceId': 'svc1',
        'clientFirstName': 'Jane',
        'clientLastName': 'Doe',
        'clientEmail': 'jane@example.com',
        'clientPhone': '5551234567',
        'startTime': now.toIso8601String(),
        'endTime': now.add(const Duration(minutes: 60)).toIso8601String(),
        'depositAmountCents': 2500,
        'status': 'confirmed',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'cancellationPolicyAcknowledged': true,
        'userId': 'uid123',
        'healthDisclosureDetails': {'skinConditions': 'Yes', 'allergies': 'Not applicable'},
        'requiredAcknowledgmentsAcceptedAt': now.toIso8601String(),
        'cancellationPolicySnapshot': {
          'acknowledged': true,
          'acknowledgedAt': now.toIso8601String(),
          'policyVersion': '1.0',
          'policyTextHash': null,
        },
      };
      final apt = AppointmentModel.fromJson(json);
      expect(apt.userId, 'uid123');
      expect(apt.healthDisclosureDetails, isNotNull);
      expect(apt.healthDisclosureDetails!['skinConditions'], 'Yes');
      expect(apt.healthDisclosureDetails!['allergies'], 'Not applicable');
      expect(apt.requiredAcknowledgmentsAcceptedAt, isNotNull);
      expect(apt.cancellationPolicySnapshot, isNotNull);
      expect(apt.cancellationPolicySnapshot!.acknowledged, true);
      expect(apt.cancellationPolicySnapshot!.policyVersion, '1.0');
      final back = apt.toJson();
      expect(back['userId'], 'uid123');
      expect(back['healthDisclosureDetails'], isA<Map>());
      expect(back['cancellationPolicySnapshot'], isA<Map>());
    });

    test('fromJson with missing new fields (backwards compat)', () {
      final now = DateTime.now();
      final json = {
        'id': 'apt2',
        'serviceId': 'svc2',
        'clientFirstName': 'John',
        'clientLastName': 'Doe',
        'clientEmail': 'john@example.com',
        'clientPhone': '5559876543',
        'startTime': now.toIso8601String(),
        'endTime': now.add(const Duration(minutes: 30)).toIso8601String(),
        'depositAmountCents': 1000,
        'status': 'confirmed',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'cancellationPolicyAcknowledged': false,
      };
      final apt = AppointmentModel.fromJson(json);
      expect(apt.userId, isNull);
      expect(apt.healthDisclosureDetails, isNull);
      expect(apt.requiredAcknowledgmentsAcceptedAt, isNull);
      expect(apt.cancellationPolicySnapshot, isNull);
      expect(apt.cancellationPolicyAcknowledged, false);
    });

    test('CancellationPolicySnapshot fromJson/toJson', () {
      final now = DateTime.now();
      final json = {
        'acknowledged': true,
        'acknowledgedAt': now.toIso8601String(),
        'policyVersion': '1.0',
        'policyTextHash': null,
      };
      final snap = CancellationPolicySnapshot.fromJson(json);
      expect(snap.acknowledged, true);
      expect(snap.policyVersion, '1.0');
      expect(snap.policyTextHash, isNull);
      final back = snap.toJson();
      expect(back['acknowledged'], true);
      expect(back['policyVersion'], '1.0');
    });
  });
}
