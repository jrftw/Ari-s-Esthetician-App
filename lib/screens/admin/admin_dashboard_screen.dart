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
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

// MARK: - Admin Dashboard Screen
/// Main admin dashboard showing overview and navigation
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

// MARK: - Admin Dashboard Screen State
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  int _unreadNotificationsCount = 0;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _checkSuperAdmin();
  }

  /// Check if current user is super admin
  Future<void> _checkSuperAdmin() async {
    try {
      final isSuperAdmin = await _authService.isSuperAdmin();
      if (mounted) {
        setState(() {
          _isSuperAdmin = isSuperAdmin;
        });
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to check super admin status',
        tag: 'AdminDashboardScreen',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Load unread notifications count with real-time updates
  void _loadUnreadCount() {
    final stream = _notificationService.getUnreadNotificationsCountStream();
    stream.listen(
      (count) {
        if (mounted) {
          setState(() {
            _unreadNotificationsCount = count;
          });
        }
      },
      onError: (error, stackTrace) {
        logError(
          'Failed to load unread notifications count',
          tag: 'AdminDashboardScreen',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Notification icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  logInfo('Notifications button tapped', tag: 'AdminDashboardScreen');
                  context.push(AppConstants.routeAdminNotifications);
                },
                tooltip: 'Notifications',
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationsCount > 99 ? '99+' : '$_unreadNotificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
            title: 'Notifications',
            subtitle: 'View appointment notifications and history',
            icon: Icons.notifications,
            route: AppConstants.routeAdminNotifications,
            badgeCount: _unreadNotificationsCount > 0 ? _unreadNotificationsCount : null,
          ),
          
          _buildNavCard(
            context,
            title: 'Estimated Earnings',
            subtitle: 'View earnings and statistics',
            icon: Icons.attach_money,
            route: AppConstants.routeAdminEarnings,
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
          
          // MARK: - Super Admin Only Features
          if (_isSuperAdmin) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Super Admin',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildNavCard(
              context,
              title: 'Software Enhancements',
              subtitle: 'Report bugs, request features, make suggestions',
              icon: Icons.bug_report,
              route: AppConstants.routeAdminSoftwareEnhancements,
            ),
          ],
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
    int? badgeCount,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(icon, color: AppColors.sunflowerYellow, size: 32),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
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
