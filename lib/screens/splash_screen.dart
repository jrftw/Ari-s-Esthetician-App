/*
 * Filename: splash_screen.dart
 * Purpose: Initial splash screen shown while app initializes
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Flutter, go_router, firebase_auth
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/logging/app_logger.dart';
import '../core/theme/theme_extensions.dart';
import '../../services/auth_service.dart';
import '../../services/view_mode_service.dart';

// MARK: - Splash Screen
/// Initial screen displayed while checking authentication state
/// Redirects to appropriate screen based on user authentication
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// MARK: - Splash Screen State
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    logUI('SplashScreen initState called', tag: 'SplashScreen');
    logWidgetLifecycle('SplashScreen', 'initState', tag: 'SplashScreen');
    _checkAuthAndNavigate();
  }

  // MARK: - Navigation Logic
  /// Check authentication state and navigate accordingly
  /// Waits for auth state restoration and checks for session restoration if "keep signed in" is enabled
  Future<void> _checkAuthAndNavigate() async {
    logUI('Starting auth check and navigation', tag: 'SplashScreen');
    logLoading('Waiting 2 seconds before navigation', tag: 'SplashScreen');
    
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    if (!mounted) {
      logWarning('Widget not mounted - aborting navigation', tag: 'SplashScreen');
      return;
    }

    logAuth('Checking current user', tag: 'SplashScreen');
    final authService = AuthService();
    
    // MARK: - Wait for Auth State Restoration
    /// Wait for Firebase Auth to restore session from local storage
    /// Firebase Auth persists sessions automatically, so we always check for existing sessions
    /// This is especially important for web/simulator where refresh can clear auth state temporarily
    /// and for hot reload during development
    logLoading('Waiting for auth state restoration...', tag: 'SplashScreen');
    
    // Always check for existing Firebase Auth session (Firebase persists automatically)
    User? user = await authService.checkExistingSession();
    
    // If no user found, also try the waitForAuthStateRestoration method
    if (user == null) {
      user = await authService.waitForAuthStateRestoration();
    }
    
    logAuth('User found after restoration: ${user?.email ?? "null"}', tag: 'SplashScreen');
    
    // MARK: - Session Restoration
    /// If no user found, try to restore session (Firebase Auth persists automatically)
    /// The keepSignedIn preference is mainly for UI, but we still check it
    if (user == null) {
      logAuth('No user found - checking for session restoration', tag: 'SplashScreen');
      final restoredUser = await authService.restoreSessionIfEnabled();
      if (restoredUser != null) {
        user = restoredUser;
        logAuth('Session restored: ${restoredUser.email}', tag: 'SplashScreen');
      }
    }
    
    if (user != null) {
      logAuth('User is logged in - checking role', tag: 'SplashScreen');
      // User is logged in, check role and navigate
      logLoading('Checking admin status...', tag: 'SplashScreen');
      final isAdmin = await authService.isAdmin();
      logAuth('Admin status: $isAdmin', tag: 'SplashScreen');
      
      // Initialize view mode service
      final viewModeService = ViewModeService.instance;
      await viewModeService.initialize(isAdmin: isAdmin);
      logInfo('View mode service initialized', tag: 'SplashScreen');
      
      if (isAdmin) {
        logRouter('Navigating to /admin', tag: 'SplashScreen');
        context.go('/admin');
      } else {
        logRouter('Navigating to /booking (client)', tag: 'SplashScreen');
        context.go('/booking');
      }
    } else {
      logAuth('No user logged in - navigating to welcome screen', tag: 'SplashScreen');
      // User is not logged in, go to welcome screen
      logRouter('Navigating to welcome screen', tag: 'SplashScreen');
      context.go('/welcome');
    }
    
    logComplete('Navigation complete', tag: 'SplashScreen');
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building SplashScreen widget', tag: 'SplashScreen');
    logWidgetLifecycle('SplashScreen', 'build', tag: 'SplashScreen');
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MARK: - Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.sunflowerYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.spa,
                size: 60,
                color: context.themePrimaryTextColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // MARK: - App Name
            Text(
              'Ari\'s Esthetician',
              style: AppTypography.headlineMedium.copyWith(
                color: context.themePrimaryTextColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // MARK: - Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.sunflowerYellow),
            ),
          ],
        ),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add animated logo
// - Add version number display
// - Add network connectivity check
// - Add app update check
