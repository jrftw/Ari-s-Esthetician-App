/*
 * Filename: theme_extensions.dart
 * Purpose: Theme-aware color helpers so all screens stay readable in light and dark mode
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Flutter Material Design
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';

// MARK: - Theme Color Extensions
/// Use these in build() so text and icons always contrast with the current theme.
/// Ensures everything can be seen in both light and dark mode.
extension ThemeColorExtensions on BuildContext {
  /// Primary text/icon color (onSurface) – dark in light mode, light in dark mode
  Color get themePrimaryTextColor => Theme.of(this).colorScheme.onSurface;

  /// Secondary text/icon color (onSurfaceVariant) – muted but readable
  Color get themeSecondaryTextColor => Theme.of(this).colorScheme.onSurfaceVariant;

  /// Surface color for cards/containers – follows theme
  Color get themeSurfaceColor => Theme.of(this).colorScheme.surface;

  /// Whether the current theme is dark (for conditional logic if needed)
  bool get themeIsDark => Theme.of(this).brightness == Brightness.dark;
}
