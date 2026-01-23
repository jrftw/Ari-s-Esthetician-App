/*
 * Filename: splash_screen.dart
 * Purpose: Initial splash screen shown while app initializes
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
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
  Future<void> _checkAuthAndNavigate() async {
    logUI('Starting auth check and navigation', tag: 'SplashScreen');
    logLoading('Waiting 2 seconds before navigation', tag: 'SplashScreen');
    
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    if (!mounted) {
      logWarning('Widget not mounted - aborting navigation', tag: 'SplashScreen');
      return;
    }

    logAuth('Checking current user', tag: 'SplashScreen');
    final user = FirebaseAuth.instance.currentUser;
    logAuth('User found: ${user?.email ?? "null"}', tag: 'SplashScreen');
    
    if (user != null) {
      logAuth('User is logged in - checking role', tag: 'SplashScreen');
      // User is logged in, check role and navigate
      final authService = AuthService();
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
      backgroundColor: AppColors.backgroundCream,
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
              child: const Icon(
                Icons.spa,
                size: 60,
                color: AppColors.darkBrown,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // MARK: - App Name
            Text(
              'Ari\'s Esthetician',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.darkBrown,
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
