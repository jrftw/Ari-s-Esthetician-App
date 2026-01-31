/*
 * Filename: app_theme.dart
 * Purpose: Centralized sunflower-themed design system for the entire application
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter Material Design
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

// MARK: - Theme Data Provider
/// Provides the sunflower-themed app theme
class AppTheme {
  /// Get the light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // MARK: - Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.sunflowerYellow,
        secondary: AppColors.softCream,
        tertiary: AppColors.mutedGreen,
        surface: AppColors.backgroundCream,
        background: AppColors.backgroundCream,
        error: AppColors.errorRed,
        onPrimary: AppColors.darkBrown,
        onSecondary: AppColors.darkBrown,
        onSurface: AppColors.darkBrown,
        onBackground: AppColors.darkBrown,
        onError: Colors.white,
      ),

      // MARK: - Scaffold
      // Transparent so AuraScreenWrapper's AuraBackground (cream + orbs) shows through
      scaffoldBackgroundColor: Colors.transparent,

      // MARK: - App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.appBarTitle,
        iconTheme: const IconThemeData(
          color: AppColors.darkBrown,
          size: 24,
        ),
      ),

      // MARK: - Card
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // MARK: - Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sunflowerYellow,
          foregroundColor: AppColors.darkBrown,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sunflowerYellow,
          side: const BorderSide(color: AppColors.sunflowerYellow, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sunflowerYellow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // MARK: - Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sunflowerYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkBrown),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),

      // MARK: - Typography (explicit color so default text is readable in light mode)
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
      ),

      // MARK: - Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.titleLarge,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // MARK: - Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // MARK: - Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softCream,
        selectedColor: AppColors.sunflowerYellow,
        labelStyle: AppTypography.bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // MARK: - Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Get the dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // MARK: - Color Scheme (Dark)
      colorScheme: ColorScheme.dark(
        primary: AppColors.sunflowerYellow,
        secondary: AppColors.softCream,
        tertiary: AppColors.mutedGreen,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.errorRed,
        onPrimary: AppColors.darkBrown,
        onSecondary: AppColors.darkBrown,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),

      // MARK: - Scaffold (Dark)
      scaffoldBackgroundColor: Colors.transparent,

      // MARK: - App Bar (Dark)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.appBarTitle.copyWith(color: AppColors.darkTextPrimary),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
      ),

      // MARK: - Card (Dark)
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shadowColor: AppColors.darkShadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // MARK: - Button Themes (Dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sunflowerYellow,
          foregroundColor: AppColors.darkBrown,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sunflowerYellow,
          side: const BorderSide(color: AppColors.sunflowerYellow, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sunflowerYellow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // MARK: - Input Decoration (Dark)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sunflowerYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      ),

      // MARK: - Typography (Dark)
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkTextPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.darkTextPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.darkTextPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.darkTextPrimary),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkTextPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.darkTextPrimary),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.darkTextPrimary),
      ),

      // MARK: - Dialog (Dark)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
      ),

      // MARK: - Bottom Sheet (Dark)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // MARK: - Chip (Dark)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.sunflowerYellow,
        labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // MARK: - Divider (Dark)
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add dark mode support with full theme
// - Implement theme customization from admin panel
// - Add animation transitions between screens
// - Consider adding custom icon themes
