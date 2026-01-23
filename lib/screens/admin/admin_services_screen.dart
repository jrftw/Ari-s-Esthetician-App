/*
 * Filename: admin_services_screen.dart
 * Purpose: Admin screen for managing services (add, edit, delete)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

// MARK: - Admin Services Screen
/// Screen for managing services offered by the business
class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
      ),
      body: Center(
        child: Text(
          'Services Management - To be implemented',
          style: AppTypography.bodyLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show add service dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Implement service list
// - Add service creation/edit form
// - Add service deletion with confirmation
// - Add service reordering
