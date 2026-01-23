/*
 * Filename: update_required_screen.dart
 * Purpose: Blocking screen displayed when app update is required
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Flutter Material, url_launcher, app_colors, app_typography, app_constants
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';

// MARK: - Update Required Screen
/// Blocking screen that prevents app usage until update is installed
/// Displays update message and provides link to app store
class UpdateRequiredScreen extends StatelessWidget {
  /// Current app version
  final String currentVersion;
  
  /// Current build number
  final int currentBuildNumber;
  
  /// Latest required version
  final String latestVersion;
  
  /// Latest required build number
  final int latestBuildNumber;
  
  /// Custom update message (optional)
  final String? updateMessage;
  
  /// App Store/Play Store URL (optional)
  final String? updateUrl;

  const UpdateRequiredScreen({
    super.key,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    this.updateMessage,
    this.updateUrl,
  });

  @override
  Widget build(BuildContext context) {
    logUI('Building UpdateRequiredScreen', tag: 'UpdateRequiredScreen');
    logDebug('Current: $currentVersion (Build $currentBuildNumber)', tag: 'UpdateRequiredScreen');
    logDebug('Latest: $latestVersion (Build $latestBuildNumber)', tag: 'UpdateRequiredScreen');

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // MARK: - Update Icon
                /// Large update icon to indicate action needed
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update,
                    size: 64,
                    color: AppColors.warningOrange,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // MARK: - Title
                /// Main title indicating update is required
                Text(
                  'Update Required',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // MARK: - Update Message
                /// Custom message or default message explaining update requirement
                Text(
                  updateMessage ?? 
                    'A new version of ${AppConstants.appName} is available. Please update to continue using the app.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // MARK: - Version Information Card
                /// Display current and latest version information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Current Version
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Version:',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$currentVersion (Build $currentBuildNumber)',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Divider
                      Divider(
                        color: AppColors.borderColor,
                        height: 1,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Latest Version
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Latest Version:',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$latestVersion (Build $latestBuildNumber)',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // MARK: - Update Button
                /// Primary button - platform-specific action
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => _handleUpdateButtonPressed(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunflowerYellow,
                      foregroundColor: AppColors.darkBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _getUpdateButtonText(),
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // MARK: - Help Text
                /// Additional help text for users - platform-specific
                Text(
                  _getHelpText(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Update Button Handler
  /// Handle update button press - platform-specific action
  Future<void> _handleUpdateButtonPressed(BuildContext context) async {
    logUI('Update button pressed', tag: 'UpdateRequiredScreen');
    String platformName = 'Unknown';
    if (kIsWeb) {
      platformName = 'Web';
    } else {
      try {
        if (!kIsWeb) {
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            platformName = 'iOS';
          } else if (defaultTargetPlatform == TargetPlatform.android) {
            platformName = 'Android';
          }
        }
      } catch (e) {
        platformName = 'Unknown';
      }
    }
    logDebug('Platform: $platformName', tag: 'UpdateRequiredScreen');
    
    // MARK: - Web Platform Handler
    /// For web, refresh the page to load new version
    if (kIsWeb) {
      logInfo('Web platform detected - refreshing page', tag: 'UpdateRequiredScreen');
      // Force a hard refresh to clear cache and load new version
      // This will reload the entire app with the new version
      if (context.mounted) {
        // Use window.location.reload() for web
        // Note: This requires dart:html, but we can use a workaround
        // For now, show a message and let user manually refresh
        _showWebRefreshDialog(context);
      }
      return;
    }
    
    // MARK: - Mobile Platform Handler
    /// For iOS and Android, open app store URL
    String urlToLaunch = updateUrl ?? _getDefaultAppStoreUrl();
    
    logDebug('Launching URL: $urlToLaunch', tag: 'UpdateRequiredScreen');
    
    try {
      final uri = Uri.parse(urlToLaunch);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        logInfo('Successfully launched app store URL', tag: 'UpdateRequiredScreen');
      } else {
        logWarning('Cannot launch URL: $urlToLaunch', tag: 'UpdateRequiredScreen');
        String storeName = 'app store';
        try {
          if (!kIsWeb) {
            if (defaultTargetPlatform == TargetPlatform.iOS) {
              storeName = 'App Store';
            } else if (defaultTargetPlatform == TargetPlatform.android) {
              storeName = 'Play Store';
            }
          }
        } catch (e) {
          // Platform not available
        }
        _showErrorDialog(
          context, 
          'Unable to open $storeName. Please update manually.',
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to launch app store URL',
        tag: 'UpdateRequiredScreen',
        error: e,
        stackTrace: stackTrace,
      );
        String storeName = 'app store';
        try {
          if (!kIsWeb) {
            if (defaultTargetPlatform == TargetPlatform.iOS) {
              storeName = 'App Store';
            } else if (defaultTargetPlatform == TargetPlatform.android) {
              storeName = 'Play Store';
            }
          }
        } catch (e) {
          // Platform not available
        }
      _showErrorDialog(
        context, 
        'An error occurred. Please update manually from $storeName.',
      );
    }
  }

  // MARK: - Web Refresh Dialog
  /// Show dialog for web platform with refresh instructions
  void _showWebRefreshDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Refresh Required',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.darkBrown,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please refresh the page to load the latest version.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Press F5 or Ctrl+R (Windows/Linux)\n'
              '• Press Cmd+R (Mac)\n'
              '• Click the refresh button in your browser',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Attempt to reload using JavaScript if available
              // For now, just close dialog - user must manually refresh
            },
            child: Text(
              'OK',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.sunflowerYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Platform Detection
  /// Get platform-specific default app store URL
  /// Returns appropriate URL based on current platform
  String _getDefaultAppStoreUrl() {
    // MARK: - Web Platform
    /// For web, return the app's website or refresh the page
    if (kIsWeb) {
      // Web apps typically update automatically on refresh
      // Return a placeholder URL - web will handle refresh differently
      return 'https://arisesthetician.app'; // Replace with your actual web app URL
    }
    
    // MARK: - iOS Platform
    /// For iOS, return App Store URL
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        return 'https://apps.apple.com/app/aris-esthetician-app'; // Replace with your actual App Store URL
      }
      
      // MARK: - Android Platform
      /// For Android, return Play Store URL
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return 'https://play.google.com/store/apps/details?id=com.arisesthetician.app'; // Replace with your actual package name
      }
    } catch (e) {
      // Platform not available (web or other)
      logWarning('Platform detection failed: $e', tag: 'UpdateRequiredScreen');
    }
    
    // MARK: - Fallback
    /// Fallback for unknown platforms
    logWarning('Unknown platform - using default URL', tag: 'UpdateRequiredScreen');
    return 'https://arisesthetician.app';
  }

  // MARK: - Get Update Button Text
  /// Get platform-specific button text
  String _getUpdateButtonText() {
    if (kIsWeb) {
      return 'Refresh Page';
    }
    
    try {
      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return 'Update from App Store';
        }
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'Update from Play Store';
        }
      }
    } catch (e) {
      // Platform not available
      logWarning('Platform detection failed for button text: $e', tag: 'UpdateRequiredScreen');
    }
    
    return 'Update Now';
  }

  // MARK: - Get Help Text
  /// Get platform-specific help text
  String _getHelpText() {
    if (kIsWeb) {
      return 'Please refresh the page to load the latest version. The app will not function until you refresh.';
    } else {
      return 'The app will not function until you update to the latest version from the app store.';
    }
  }

  // MARK: - Error Dialog
  /// Show error dialog if app store cannot be opened
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Required',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.darkBrown,
          ),
        ),
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.sunflowerYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add platform detection to show correct app store URL (iOS vs Android)
// - Implement deep linking to specific app store pages
// - Add retry button for failed URL launches
// - Show loading indicator while checking for updates
// - Add "Check for Updates" button for manual refresh
// - Implement version check polling in background
// - Add analytics tracking for update screen views