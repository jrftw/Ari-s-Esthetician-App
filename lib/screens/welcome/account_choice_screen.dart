/*
 * Filename: account_choice_screen.dart
 * Purpose: Screen allowing users to create account or book as guest
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

// MARK: - Account Choice Screen
/// Screen presenting options to create account or book as guest
/// Explains benefits of each option
class AccountChoiceScreen extends StatelessWidget {
  const AccountChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logUI('Building AccountChoiceScreen', tag: 'AccountChoiceScreen');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // MARK: - Title
                Text(
                  'Choose How to Continue',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Create an account to save your information and view booking history, or continue as a guest.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // MARK: - Create Account Option
                _buildOptionCard(
                  context: context,
                  icon: Icons.person_add,
                  title: 'Create Account',
                  benefits: [
                    'Save your information for faster booking',
                    'View your booking history',
                    'Manage upcoming appointments',
                    'Receive appointment reminders',
                  ],
                  buttonText: 'Sign Up',
                  buttonColor: AppColors.sunflowerYellow,
                  onPressed: () {
                    logRouter('Navigating to signup', tag: 'AccountChoiceScreen');
                    context.push('/signup');
                  },
                ),
                
                const SizedBox(height: 24),
                
                // MARK: - Guest Booking Option
                _buildOptionCard(
                  context: context,
                  icon: Icons.shopping_cart,
                  title: 'Book as Guest',
                  benefits: [
                    'No account required',
                    'Quick and easy booking',
                    'Pay deposit and confirm',
                    'Receive email confirmation',
                  ],
                  buttonText: 'Continue as Guest',
                  buttonColor: AppColors.mutedGreen,
                  onPressed: () {
                    logRouter('Navigating to booking as guest', tag: 'AccountChoiceScreen');
                    context.go('/booking');
                  },
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Option Card
  /// Builds a card for account or guest option
  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<String> benefits,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: buttonColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: buttonColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Benefits List
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: buttonColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 24),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: AppColors.darkBrown,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: AppTypography.buttonText.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add account creation benefits animation
// - Add guest booking limitations info
// - Add social login options
// - Add "Why create account?" expandable section
