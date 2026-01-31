/*
 * Filename: app_typography.dart
 * Purpose: Centralized typography system for consistent text styling
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Flutter Material Design
 * Platform Compatibility: iOS, Android, Web
 *
 * Text color: Base styles do NOT set color so text inherits from Theme. This
 * keeps dark mode readable (light text on dark background) and light mode
 * correct (dark text on light background) without hardcoding brown everywhere.
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'app_colors.dart';

// MARK: - Typography Constants
/// Centralized text styles for the application
/// Color is omitted so text uses theme's onSurface/onBackground (readable in light and dark)
class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  // MARK: - Base Text Style (no color: inherits from Theme for dark/light readability)
  static const TextStyle _baseTextStyle = TextStyle(
    fontFamily: 'Sunflower',
    letterSpacing: 0.5,
  );

  // MARK: - Display Styles
  /// Large display text (hero sections)
  static TextStyle get displayLarge => _baseTextStyle.copyWith(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// Medium display text
  static TextStyle get displayMedium => _baseTextStyle.copyWith(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// Small display text
  static TextStyle get displaySmall => _baseTextStyle.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // MARK: - Headline Styles
  /// Large headline text
  static TextStyle get headlineLarge => _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Medium headline text
  static TextStyle get headlineMedium => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Small headline text
  static TextStyle get headlineSmall => _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // MARK: - Title Styles
  /// Large title text
  static TextStyle get titleLarge => _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Medium title text
  static TextStyle get titleMedium => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.15,
  );

  /// Small title text
  static TextStyle get titleSmall => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // MARK: - Body Styles
  /// Large body text
  static TextStyle get bodyLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Medium body text (default)
  static TextStyle get bodyMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.25,
  );

  /// Small body text
  static TextStyle get bodySmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.4,
  );

  // MARK: - Label Styles
  /// Large label text
  static TextStyle get labelLarge => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Medium label text
  static TextStyle get labelMedium => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Small label text
  static TextStyle get labelSmall => _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // MARK: - Specialized Styles (no explicit color: inherit from Theme for dark mode)
  /// App bar title style
  static TextStyle get appBarTitle => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  /// Button text style
  static TextStyle get buttonText => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  /// Caption text style
  static TextStyle get caption => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  /// Overline text style
  static TextStyle get overline => _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.5,
  );
}

// Suggestions For Features and Additions Later:
// - Add font size scaling for accessibility
// - Implement custom font loading from assets
// - Add text style variants (bold, italic, etc.)
// - Consider adding text shadow styles for special effects
