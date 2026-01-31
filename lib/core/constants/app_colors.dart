/*
 * Filename: app_colors.dart
 * Purpose: Centralized color palette for the sunflower-themed design system
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter Material Design
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';

// MARK: - Color Constants
/// Centralized color definitions for the sunflower theme
/// All colors are defined here to allow easy theme customization later
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // MARK: - Primary Colors (Sunflower Theme)
  /// Main sunflower yellow - primary brand color
  static const Color sunflowerYellow = Color(0xFFFFD700); // Warm golden yellow
  
  /// Soft cream - secondary brand color
  static const Color softCream = Color(0xFFFFF8E1); // Light cream
  
  /// Muted green - accent color
  static const Color mutedGreen = Color(0xFF8BC34A); // Soft green
  
  /// Dark brown - text and contrast color
  static const Color darkBrown = Color(0xFF5D4037); // Rich brown

  // MARK: - Background Colors
  /// Main background color
  static const Color backgroundCream = Color(0xFFFFFBF0); // Very light cream
  
  /// Card background
  static const Color cardBackground = Colors.white;

  // MARK: - Text Colors
  /// Primary text color
  static const Color textPrimary = Color(0xFF5D4037); // Dark brown
  
  /// Secondary text color
  static const Color textSecondary = Color(0xFF8D6E63); // Medium brown
  
  /// Text on light backgrounds
  static const Color textOnLight = Color(0xFF5D4037);
  
  /// Text on dark backgrounds
  static const Color textOnDark = Colors.white;

  // MARK: - Status Colors
  /// Success/confirmed status
  static const Color successGreen = Color(0xFF4CAF50);
  
  /// Error/danger status
  static const Color errorRed = Color(0xFFE53935);
  
  /// Warning status
  static const Color warningOrange = Color(0xFFFF9800);
  
  /// Info status
  static const Color infoBlue = Color(0xFF2196F3);

  // MARK: - UI Element Colors
  /// Border color for inputs and dividers
  static const Color borderColor = Color(0xFFE0E0E0);
  
  /// Shadow color for cards and elevations
  static const Color shadowColor = Color(0x1A000000); // 10% opacity black
  
  /// Disabled element color
  static const Color disabledColor = Color(0xFFBDBDBD);

  // MARK: - Appointment Status Colors
  /// Confirmed appointment
  static const Color statusConfirmed = Color(0xFF4CAF50);
  
  /// Pending appointment
  static const Color statusPending = Color(0xFFFF9800);
  
  /// Completed appointment
  static const Color statusCompleted = Color(0xFF2196F3);
  
  /// Cancelled appointment
  static const Color statusCancelled = Color(0xFF9E9E9E);
  
  /// No-show appointment
  static const Color statusNoShow = Color(0xFFE53935);

  // MARK: - Aura / Glow Colors
  /// Soft golden aura - complements sunflower, used for background orbs and glows
  static const Color auraGolden = Color(0x33FFD700); // ~20% sunflower
  /// Warm cream aura - very soft, for ambient background orbs
  static const Color auraCream = Color(0x22FFF8E1); // ~13% soft cream
  /// Soft lavender aura - subtle spa/calm accent for orbs
  static const Color auraLavender = Color(0x1AE8EAF6); // ~10% light lavender
  /// Muted green aura - soft accent for secondary orbs
  static const Color auraMutedGreen = Color(0x228BC34A); // ~13% muted green
  /// Stronger golden glow for emphasis (e.g. card glow)
  static const Color auraGlowStrong = Color(0x28FFD700); // ~16% sunflower

  // MARK: - Dark Theme Colors
  /// Dark theme background
  static const Color darkBackground = Color(0xFF1C1917);
  /// Dark theme surface (cards, app bar)
  static const Color darkSurface = Color(0xFF292524);
  /// Dark theme surface variant
  static const Color darkSurfaceVariant = Color(0xFF44403C);
  /// Text on dark backgrounds (primary)
  static const Color darkTextPrimary = Color(0xFFFAFAF9);
  /// Text on dark backgrounds (secondary)
  static const Color darkTextSecondary = Color(0xFFA8A29E);
  /// Dark theme border
  static const Color darkBorder = Color(0xFF57534E);
  /// Dark theme shadow
  static const Color darkShadow = Color(0x33000000);
  /// Dark theme aura orbs (softer golden/cream for dark bg)
  static const Color darkAuraGolden = Color(0x22FFD700);
  static const Color darkAuraCream = Color(0x18FFF8E1);
  static const Color darkAuraLavender = Color(0x12E8EAF6);
  static const Color darkAuraMutedGreen = Color(0x158BC34A);
}

// Suggestions For Features and Additions Later:
// - Add color opacity variants (e.g., sunflowerYellow.withOpacity(0.5))
// - Implement color theming from admin settings
// - Add accessibility contrast checking
// - Consider adding gradient definitions
