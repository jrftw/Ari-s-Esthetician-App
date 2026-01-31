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
                    color: AppColors.sunflowerYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.spa,
                    size: 70,
                    color: AppColors.darkBrown,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // MARK: - App Name
                Text(
                  'Ari\'s Esthetician',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Book Your Appointment Online',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // MARK: - Features Section
                _buildFeatureSection(),
                
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
  Widget _buildFeatureSection() {
    return Column(
      children: [
        _buildFeatureItem(
          icon: Icons.calendar_today,
          title: 'Easy Booking',
          description: 'Schedule your appointment in just a few clicks',
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(
          icon: Icons.payment,
          title: 'Secure Payments',
          description: 'Pay your deposit safely with Stripe',
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(
          icon: Icons.notifications,
          title: 'Reminders',
          description: 'Get email reminders before your appointment',
        ),
        const SizedBox(height: 24),
        _buildFeatureItem(
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
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.sunflowerYellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.sunflowerYellow,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
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
              backgroundColor: AppColors.sunflowerYellow,
              foregroundColor: AppColors.darkBrown,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Get Started',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.darkBrown,
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
              foregroundColor: AppColors.darkBrown,
              side: BorderSide(color: AppColors.sunflowerYellow, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue as Guest',
              style: AppTypography.buttonText.copyWith(
                color: AppColors.darkBrown,
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
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
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
