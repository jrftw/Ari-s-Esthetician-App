/*
 * Filename: admin_dashboard_screen.dart
 * Purpose: Main admin dashboard with overview statistics and quick actions
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter, go_router
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../services/view_mode_service.dart';

// MARK: - Admin Dashboard Screen
/// Main admin dashboard showing overview and navigation
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              logInfo('Settings button tapped', tag: 'AdminDashboardScreen');
              context.push(AppConstants.routeSettings);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // MARK: - Quick Actions
          Text(
            'Quick Actions',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // MARK: - View as Client Action
          _buildViewAsClientCard(context),
          const SizedBox(height: 8),
          
          // MARK: - Navigation Cards
          _buildNavCard(
            context,
            title: 'Services',
            subtitle: 'Manage services and pricing',
            icon: Icons.spa,
            route: AppConstants.routeAdminServices,
          ),
          
          _buildNavCard(
            context,
            title: 'Categories',
            subtitle: 'Manage service categories',
            icon: Icons.category,
            route: AppConstants.routeAdminCategories,
          ),
          
          _buildNavCard(
            context,
            title: 'Appointments',
            subtitle: 'View and manage appointments',
            icon: Icons.calendar_today,
            route: AppConstants.routeAdminAppointments,
          ),
          
          _buildNavCard(
            context,
            title: 'Clients',
            subtitle: 'View client directory',
            icon: Icons.people,
            route: AppConstants.routeAdminClients,
          ),
          
          _buildNavCard(
            context,
            title: 'Settings',
            subtitle: 'Business settings and branding',
            icon: Icons.settings,
            route: AppConstants.routeAdminSettings,
          ),
        ],
      ),
    );
  }

  // MARK: - Helper Widgets
  /// Build navigation card for admin features
  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.sunflowerYellow, size: 32),
        title: Text(title, style: AppTypography.titleMedium),
        subtitle: Text(subtitle, style: AppTypography.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }

  /// Build "View as Client" quick action card
  /// Allows admins to switch to client view to see the booking experience
  Widget _buildViewAsClientCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.sunflowerYellow.withOpacity(0.1),
      child: ListTile(
        leading: Icon(
          Icons.visibility,
          color: AppColors.sunflowerYellow,
          size: 32,
        ),
        title: Text(
          'View as Client',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'See how clients experience the booking flow',
          style: AppTypography.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          logInfo('Admin switching to client view', tag: 'AdminDashboardScreen');
          final viewModeService = ViewModeService.instance;
          viewModeService.switchToClientView();
          context.go(AppConstants.routeClientBooking);
        },
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add statistics cards (today's appointments, revenue, etc.)
// - Add recent activity feed
// - Add quick appointment creation
// - Add notifications/alerts
