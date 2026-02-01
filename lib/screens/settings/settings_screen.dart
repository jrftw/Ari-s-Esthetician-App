/*
 * Filename: settings_screen.dart
 * Purpose: General settings screen with appearance (theme + aura), changelog, and logout
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Flutter, go_router, firebase_auth, preferences_service
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_version.dart';
import '../../core/logging/app_logger.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../../core/theme/theme_extensions.dart';

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
  final PreferencesService _prefs = PreferencesService.instance;
  
  // MARK: - State Variables
  bool _isLoggingOut = false;
  User? _currentUser;
  bool _isChangelogExpanded = false;
  // Theme forced to light only for now (dark and auto disabled)
  bool _auraEnabled = false;
  String _auraIntensity = kAuraIntensityMedium;
  String _auraColorTheme = kAuraColorThemeWarm;

  /// Auth state subscription; cancelled in dispose to prevent leak and setState-after-dispose.
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    logUI('SettingsScreen initState called', tag: 'SettingsScreen');
    _currentUser = _authService.currentUser;
    _auraEnabled = _prefs.auraEnabledSync;
    _auraIntensity = _prefs.auraIntensitySync;
    _auraColorTheme = _prefs.auraColorThemeSync;
    
    // Listen to auth state changes; store subscription so it can be cancelled in dispose
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
    // Listen to theme/aura prefs so UI stays in sync if changed elsewhere
    _prefs.addListener(_onPreferencesChanged);
  }

  void _onPreferencesChanged() {
    if (mounted) {
      setState(() {
        _auraEnabled = _prefs.auraEnabledSync;
        _auraIntensity = _prefs.auraIntensitySync;
        _auraColorTheme = _prefs.auraColorThemeSync;
      });
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _prefs.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building SettingsScreen widget', tag: 'SettingsScreen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // MARK: - User Info Section
            if (_currentUser != null) _buildUserInfoSection(),
            
            // MARK: - Appearance Section (Theme + Aura)
            _buildAppearanceSection(),
            
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

  // MARK: - Appearance Section
  /// Build appearance section: theme (light only for now) and aura (on/off + intensity).
  /// Dark and Auto theme options are disabled; everyone uses light mode.
  Widget _buildAppearanceSection() {
    final textColor = context.themePrimaryTextColor;
    final secondaryColor = context.themeSecondaryTextColor;
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
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Appearance',
                  style: AppTypography.titleLarge.copyWith(color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // MARK: - Theme (Light Only)
            Text(
              'Theme',
              style: AppTypography.titleSmall.copyWith(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.light_mode, size: 20, color: secondaryColor),
              title: Text(
                'Light',
                style: AppTypography.bodyMedium.copyWith(color: textColor),
              ),
              subtitle: Text(
                'Dark and Auto are disabled for now.',
                style: AppTypography.bodySmall.copyWith(color: secondaryColor),
              ),
            ),
            const SizedBox(height: 20),
            // MARK: - Aura
            Text(
              'Background aura',
              style: AppTypography.titleSmall.copyWith(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _auraEnabled,
              onChanged: (bool value) {
                setState(() => _auraEnabled = value);
                _prefs.setAuraEnabled(value);
                logInfo('Aura enabled: $value', tag: 'SettingsScreen');
              },
              title: Text(
                'Show aura',
                style: AppTypography.bodyMedium.copyWith(color: textColor),
              ),
              subtitle: Text(
                'Soft glowing orbs behind screens',
                style: AppTypography.bodySmall.copyWith(color: secondaryColor),
              ),
              activeThumbColor: Theme.of(context).colorScheme.primary,
              activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              contentPadding: EdgeInsets.zero,
            ),
            if (_auraEnabled) ...[
              const SizedBox(height: 12),
              Text(
                'Aura color',
                style: AppTypography.bodySmall.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: kAuraColorThemeWarm, label: Text('Warm')),
                  ButtonSegment<String>(value: kAuraColorThemeCool, label: Text('Cool')),
                  ButtonSegment<String>(value: kAuraColorThemeSpa, label: Text('Spa')),
                  ButtonSegment<String>(value: kAuraColorThemeSunset, label: Text('Sunset')),
                ],
                selected: {_auraColorTheme},
                onSelectionChanged: (Set<String> selected) {
                  final value = selected.first;
                  setState(() => _auraColorTheme = value);
                  _prefs.setAuraColorTheme(value);
                  logInfo('Aura color theme set to $value', tag: 'SettingsScreen');
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Aura intensity',
                style: AppTypography.bodySmall.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: kAuraIntensityLow, label: Text('Low')),
                  ButtonSegment<String>(value: kAuraIntensityMedium, label: Text('Medium')),
                  ButtonSegment<String>(value: kAuraIntensityHigh, label: Text('High')),
                ],
                selected: {_auraIntensity},
                onSelectionChanged: (Set<String> selected) {
                  final value = selected.first;
                  setState(() => _auraIntensity = value);
                  _prefs.setAuraIntensity(value);
                  logInfo('Aura intensity set to $value', tag: 'SettingsScreen');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // MARK: - User Info Section
  /// Build user information section
  Widget _buildUserInfoSection() {
    final primaryColor = context.themePrimaryTextColor;
    final secondaryColor = context.themeSecondaryTextColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 24,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimary,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signed in',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: secondaryColor),
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
                    color: Theme.of(context).colorScheme.primary,
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
                    color: context.themePrimaryTextColor,
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
  /// Build changelog content aligned with CHANGELOG.md (Build 1, 2, 3, 4)
  Widget _buildChangelogContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Build 4 - 2026-01-31
        _buildChangelogVersion(
          version: '${AppVersion.version} (Build ${AppVersion.buildNumber})',
          date: '2026-01-31',
          items: [
            'Version and build number updated to 1.0.0 Build 4',
            'Changelog updated for Build 4 (1/31/2026)',
          ],
        ),
        const SizedBox(height: 20),
        // Build 3 - 2026-01-30
        _buildChangelogVersion(
          version: '1.0.0 (Build 3)',
          date: '2026-01-30',
          items: [
            'Version display now shows commit hash when deployed (next to version)',
            'Build number updated to 3',
            'Changelog updated for Build 1, 2, and 3',
          ],
        ),
        const SizedBox(height: 20),
        // Build 2 - 2026-01-22
        _buildChangelogVersion(
          version: '1.0.0 (Build 2)',
          date: '2026-01-22',
          items: [
            'Updated build number to 2',
            'Version management system updated',
          ],
        ),
        const SizedBox(height: 20),
        // Build 1 - 2026-01-22
        _buildChangelogVersion(
          version: '1.0.0 (Build 1)',
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Changelog',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.themePrimaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This changelog follows the Keep a Changelog format and Semantic Versioning. '
            'Versions follow SemVer: MAJOR.MINOR.PATCH',
            style: Theme.of(context).textTheme.bodySmall,
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
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge,
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
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
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
              color: context.themeSecondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.themeSecondaryTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'App Version',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.themeSecondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Version: ${AppVersion.version}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.themeSecondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Build: ${AppVersion.buildNumberString}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.themeSecondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (AppVersion.hasCommitHash) ...[
              const SizedBox(height: 4),
              Text(
                'Commit: ${AppVersion.commitHash}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.themeSecondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Environment: ${AppVersion.environmentString.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.themeSecondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppVersion.versionString,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
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
              foregroundColor: Theme.of(context).colorScheme.error,
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
// - Add notification preferences
// - Add language selection
// - Add about section with app info
// - Add privacy policy and terms of service links
// - Add feedback/contact option
// - Add export data option
// - Add delete account option