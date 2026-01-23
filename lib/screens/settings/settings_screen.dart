/*
 * Filename: settings_screen.dart
 * Purpose: General settings screen accessible to all users with changelog and logout option
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Flutter, go_router, firebase_auth
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_version.dart';
import '../../core/logging/app_logger.dart';
import '../../services/auth_service.dart';

// MARK: - Settings Screen
/// General settings screen accessible to all users
/// Displays changelog and logout option
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// MARK: - Settings Screen State
class _SettingsScreenState extends State<SettingsScreen> {
  // MARK: - Services
  final AuthService _authService = AuthService();
  
  // MARK: - State Variables
  bool _isLoggingOut = false;
  User? _currentUser;
  bool _isChangelogExpanded = false;

  @override
  void initState() {
    super.initState();
    logUI('SettingsScreen initState called', tag: 'SettingsScreen');
    _currentUser = _authService.currentUser;
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building SettingsScreen widget', tag: 'SettingsScreen');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // MARK: - User Info Section
            if (_currentUser != null) _buildUserInfoSection(),
            
            // MARK: - Changelog Section
            _buildChangelogSection(),
            
            const SizedBox(height: 24),
            
            // MARK: - Logout Section
            if (_currentUser != null) _buildLogoutSection(),
          ],
        ),
      ),
    );
  }

  // MARK: - User Info Section
  /// Build user information section
  Widget _buildUserInfoSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.sunflowerYellow,
              radius: 24,
              child: Icon(
                Icons.person,
                color: AppColors.darkBrown,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.email ?? 'User',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signed in',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.darkBrown.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Changelog Section
  /// Build changelog section with expandable/collapsible content
  Widget _buildChangelogSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MARK: - Changelog Header (Clickable)
          InkWell(
            onTap: () {
              setState(() {
                _isChangelogExpanded = !_isChangelogExpanded;
                logInfo(
                  'Changelog ${_isChangelogExpanded ? "expanded" : "collapsed"}',
                  tag: 'SettingsScreen',
                );
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: AppColors.sunflowerYellow,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changelog',
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  Icon(
                    _isChangelogExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.darkBrown,
                  ),
                ],
              ),
            ),
          ),
          // MARK: - Changelog Content (Expandable)
          if (_isChangelogExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildChangelogContent(),
              ),
            ),
        ],
      ),
    );
  }

  // MARK: - Changelog Content
  /// Build changelog content from CHANGELOG.md
  Widget _buildChangelogContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Version 1.0.0
        _buildChangelogVersion(
          version: '1.0.0',
          date: '2026-01-22',
          items: [
            'Initial release of Ari\'s Esthetician App',
            'Core Flutter project structure with sunflower-themed design system',
            'Firebase integration (Authentication, Firestore, Functions, Storage, Messaging)',
            'Data models for Services, Appointments, Clients, and Business Settings',
            'Authentication service with role-based access control (admin/client)',
            'Firestore service with complete CRUD operations',
            'Role-based routing with Go Router',
            'Admin dashboard screens',
            'Client booking screens',
            'Centralized logging system (AppLogger)',
            'Firestore security rules with helper functions',
            'Stripe payment integration setup',
            'Google Calendar API integration setup',
            'Global version and build number management system',
            'Environment-based version display (dev/beta/production)',
            'Comprehensive README documentation',
            'General settings screen with changelog and logout',
          ],
        ),
        const SizedBox(height: 24),
        _buildChangelogInfo(),
      ],
    );
  }

  // MARK: - Changelog Version Widget
  /// Build a version section in the changelog
  Widget _buildChangelogVersion({
    required String version,
    required String date,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version $version - $date',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.sunflowerYellow,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.sunflowerYellow,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // MARK: - Changelog Info Widget
  /// Build changelog information section
  Widget _buildChangelogInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Changelog',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This changelog follows the Keep a Changelog format and Semantic Versioning. '
            'Versions follow SemVer: MAJOR.MINOR.PATCH',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  // MARK: - Logout Section
  /// Build logout section with button
  Widget _buildLogoutSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.logout,
                  color: AppColors.errorRed,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account',
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoggingOut ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: AppTypography.buttonText,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // MARK: - Version Information
            Divider(
              color: AppColors.textSecondary.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'App Version',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Version: ${AppVersion.version}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Build: ${AppVersion.buildNumberString}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Environment: ${AppVersion.environmentString.toUpperCase()}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppVersion.versionString,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.sunflowerYellow,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Logout Handler
  /// Handle user logout
  Future<void> _handleLogout() async {
    logInfo('User initiated logout', tag: 'SettingsScreen');
    
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      logInfo('User cancelled logout', tag: 'SettingsScreen');
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut();
      logInfo('Logout successful', tag: 'SettingsScreen');
      
      if (mounted) {
        // Navigate to welcome screen
        context.go('/welcome');
      }
    } catch (e, stackTrace) {
      logError(
        'Logout failed',
        tag: 'SettingsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add theme toggle (light/dark mode)
// - Add notification preferences
// - Add language selection
// - Add about section with app info
// - Add privacy policy and terms of service links
// - Add feedback/contact option
// - Add export data option
// - Add delete account option