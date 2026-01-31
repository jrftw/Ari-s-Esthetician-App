/*
 * Filename: aura_background.dart
 * Purpose: Reusable aura/glow background and screen wrapper for app-wide atmospheric effect
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Flutter Material Design, app_colors, preferences_service (for wrapper)
 * Platform Compatibility: iOS, Android, Web
 *
 * Performance: Static layout only (no animations, no timers). Rebuilds only when
 * theme/aura preferences change via ListenableBuilder. Uses RepaintBoundary so
 * the background layer repaints independently from content above, avoiding extra
 * repaints on scroll. All preference reads are sync from in-memory cache.
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../services/preferences_service.dart';

// MARK: - Aura Background Widget
/// Paints soft gradient orbs (auras) behind content to create a calm, spa-like atmosphere.
/// Respects [enabled], [intensity], [colorThemeId], and [isDark] for customizable aura colors.
class AuraBackground extends StatelessWidget {
  /// Optional: override base background color (defaults by theme).
  final Color? backgroundColor;
  /// When false, only the base background is shown (no orbs).
  final bool enabled;
  /// Intensity: "low" (0.4), "medium" (0.7), "high" (1.0). Ignored if [enabled] is false.
  final String intensity;
  /// Aura color theme: "warm" | "cool" | "spa" | "sunset". Picks which palette to use.
  final String colorThemeId;
  /// When true, uses dark theme aura colors and background.
  final bool isDark;

  const AuraBackground({
    super.key,
    this.backgroundColor,
    this.enabled = true,
    this.intensity = kAuraIntensityMedium,
    this.colorThemeId = kAuraColorThemeWarm,
    this.isDark = false,
  });

  /// Opacity multiplier from stored intensity string.
  double get _intensityMultiplier {
    switch (intensity) {
      case kAuraIntensityLow:
        return 0.4;
      case kAuraIntensityHigh:
        return 1.0;
      default:
        return 0.7;
    }
  }

  Color _baseColor() =>
      backgroundColor ?? (isDark ? AppColors.darkBackground : AppColors.backgroundCream);

  /// Resolve the four orb colors from [colorThemeId] and [isDark].
  ({Color orb1, Color orb2, Color orb3, Color orb4}) _resolveAuraColors() {
    final d = isDark;
    switch (colorThemeId) {
      case kAuraColorThemeCool:
        return d
            ? (orb1: AppColors.darkAuraCoolBlue, orb2: AppColors.darkAuraCoolLightBlue, orb3: AppColors.darkAuraCoolTeal, orb4: AppColors.darkAuraCoolPurple)
            : (orb1: AppColors.auraCoolBlue, orb2: AppColors.auraCoolLightBlue, orb3: AppColors.auraCoolTeal, orb4: AppColors.auraCoolPurple);
      case kAuraColorThemeSpa:
        return d
            ? (orb1: AppColors.darkAuraSpaGreen, orb2: AppColors.darkAuraSpaMint, orb3: AppColors.darkAuraSpaLavender, orb4: AppColors.darkAuraSpaBlue)
            : (orb1: AppColors.auraSpaGreen, orb2: AppColors.auraSpaMint, orb3: AppColors.auraSpaLavender, orb4: AppColors.auraSpaBlue);
      case kAuraColorThemeSunset:
        return d
            ? (orb1: AppColors.darkAuraSunsetOrange, orb2: AppColors.darkAuraSunsetPink, orb3: AppColors.darkAuraSunsetYellow, orb4: AppColors.darkAuraSunsetCoral)
            : (orb1: AppColors.auraSunsetOrange, orb2: AppColors.auraSunsetPink, orb3: AppColors.auraSunsetYellow, orb4: AppColors.auraSunsetCoral);
      default:
        return d
            ? (orb1: AppColors.darkAuraGolden, orb2: AppColors.darkAuraCream, orb3: AppColors.darkAuraLavender, orb4: AppColors.darkAuraMutedGreen)
            : (orb1: AppColors.auraGolden, orb2: AppColors.auraCream, orb3: AppColors.auraLavender, orb4: AppColors.auraMutedGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final mult = enabled ? _intensityMultiplier : 0.0;
        final colors = _resolveAuraColors();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // MARK: - Base Background
            Positioned.fill(
              child: Container(
                color: _baseColor(),
              ),
            ),
            if (mult > 0) ...[
              _buildAuraOrb(
                left: width * 0.5,
                top: -height * 0.15,
                size: width * 0.9,
                color: colors.orb1,
                intensityMult: mult,
              ),
              _buildAuraOrb(
                left: -width * 0.3,
                top: height * 0.4,
                size: width * 0.85,
                color: colors.orb2,
                intensityMult: mult,
              ),
              _buildAuraOrb(
                left: width * 0.2,
                top: height * 0.6,
                size: width * 0.6,
                color: colors.orb3,
                intensityMult: mult,
              ),
              _buildAuraOrb(
                left: -width * 0.2,
                top: height * 0.05,
                size: width * 0.5,
                color: colors.orb4,
                intensityMult: mult,
              ),
            ],
          ],
        );
      },
    );
  }

  /// Builds a single soft radial-gradient orb for the aura effect.
  /// [intensityMult] scales the color opacity (0..1).
  Widget _buildAuraOrb({
    required double left,
    required double top,
    required double size,
    required Color color,
    double intensityMult = 1.0,
  }) {
    final op = color.opacity * intensityMult;
    final c = color.withOpacity(op);
    final cMid = color.withOpacity(op * 0.5);
    final cZero = color.withOpacity(0);
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c, cMid, cZero],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }
}

// MARK: - Aura Screen Wrapper
/// Wraps any screen content with the aura background; reads theme and aura prefs from PreferencesService.
/// Use inside a ListenableBuilder(listenable: PreferencesService.instance) so it rebuilds when prefs change.
class AuraScreenWrapper extends StatelessWidget {
  /// The screen widget to display on top of the aura background (e.g. Scaffold).
  final Widget child;

  const AuraScreenWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        // RepaintBoundary: aura layer repaints independently from overlay content (scroll, etc.)
        RepaintBoundary(
          child: AuraBackground(
            enabled: prefs.auraEnabledSync,
            intensity: prefs.auraIntensitySync,
            colorThemeId: prefs.auraColorThemeSync,
            isDark: isDark,
          ),
        ),
        child,
      ],
    );
  }
}

// MARK: - Aura Decoration Helpers
/// Optional aura-style box shadows for cards or containers.
/// Use with Container(decoration: BoxDecoration(boxShadow: AuraDecoration.auraCardShadows)).
class AuraDecoration {
  AuraDecoration._();

  /// Soft golden glow + default shadow for card-like elevation with aura.
  static List<BoxShadow> get auraCardShadows => [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppColors.auraGlowStrong,
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: -4,
        ),
      ];
}

// Suggestions For Features and Additions Later:
// - Optional animated subtle pulse for orbs (e.g. opacity or scale)
// - Theme-based aura intensity (e.g. reduced in dark mode)
// - Per-route aura variants (e.g. stronger golden on booking screen)
