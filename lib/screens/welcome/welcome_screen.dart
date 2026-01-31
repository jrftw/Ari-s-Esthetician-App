/*
 * Filename: welcome_screen.dart
 * Purpose: Welcome/landing screen introducing the app and its features
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
import '../../core/theme/theme_extensions.dart';
import '../../core/logging/app_logger.dart';

// MARK: - Welcome Screen
/// First screen users see - introduces the app and its features
/// Provides options to create account or continue as guest
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logUI('Building WelcomeScreen', tag: 'WelcomeScreen');
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // MARK: - Logo/Icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow,
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.spa,
                    size: 70,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // MARK: - App Name
                Text(
                  'Ari\'s Esthetician',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: context.themePrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Book Your Appointment Online',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.themeSecondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // MARK: - Features Section
                _buildFeatureSection(context),
                
                const SizedBox(height: 48),
                
                // MARK: - Action Buttons
                _buildActionButtons(context),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Feature Section
  /// Displays key features of the app
  Widget _buildFeatureSection(BuildContext context) {
    return Column(
      children: [
        _buildFeatureItem(
          context: context,
          icon: Icons.calendar_today,
          title: 'Easy Booking',
          description: 'Schedule your appointment in just a few clicks',
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(
          context: context,
          icon: Icons.payment,
          title: 'Secure Payments',
          description: 'Pay your deposit safely with Stripe',
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(
          context: context,
          icon: Icons.notifications,
          title: 'Reminders',
          description: 'Get email reminders before your appointment',
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(
          context: context,
          icon: Icons.event_available,
          title: 'Calendar Sync',
          description: 'Add appointments directly to your calendar',
        ),
      ],
    );
  }

  // MARK: - Feature Item
  /// Individual feature display
  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.themePrimaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.themeSecondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // MARK: - Action Buttons
  /// Primary action buttons for account creation or guest booking
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Create Account Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              logRouter('Navigating to account/guest choice', tag: 'WelcomeScreen');
              context.push('/account-choice');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Get Started',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Continue as Guest Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              logRouter('Navigating to booking as guest', tag: 'WelcomeScreen');
              context.go('/booking');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue as Guest',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Already have account link
        TextButton(
          onPressed: () {
            logRouter('Navigating to login', tag: 'WelcomeScreen');
            context.push('/login');
          },
          child: Text(
            'Already have an account? Sign in',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.themeSecondaryTextColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add animated logo/icon
// - Add testimonials section
// - Add social media links
// - Add app version display
// - Add terms/privacy policy links
