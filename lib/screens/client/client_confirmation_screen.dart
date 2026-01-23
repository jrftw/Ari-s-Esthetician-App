/*
 * Filename: client_confirmation_screen.dart
 * Purpose: Appointment confirmation screen after successful booking
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter, models
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

// MARK: - Client Confirmation Screen
/// Screen displayed after successful appointment booking
/// Shows appointment details and provides calendar add option
class ClientConfirmationScreen extends StatelessWidget {
  final String appointmentId;

  const ClientConfirmationScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
      ),
      body: Center(
        child: Text(
          'Confirmation Screen - Appointment ID: $appointmentId',
          style: AppTypography.bodyLarge,
        ),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Display appointment details
// - Add "Add to Calendar" functionality
// - Show deposit receipt
// - Add email confirmation status
