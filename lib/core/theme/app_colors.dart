import 'package:flutter/material.dart';

/// Radiant Dew color tokens + elevation glows.
///
/// Source of truth: doc/design-reference/screens/index.html (Tailwind config)
/// and .../radiant_dew/DESIGN.md. Card surfaces are PURE WHITE on a cream
/// background; elevation is expressed as soft, peach-tinted "glow" shadows —
/// never dark drop shadows.
abstract final class AppColors {
  // Primary — Vibrant Peach
  static const Color primary = Color(0xFF9E412C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFF8B71);
  static const Color onPrimaryContainer = Color(0xFF752311);
  static const Color primaryFixed = Color(0xFFFFDAD3);
  static const Color primaryFixedDim = Color(0xFFFFB4A4);
  static const Color onPrimaryFixedVariant = Color(0xFF7F2A18);

  // Secondary — Soft Lemon
  static const Color secondary = Color(0xFF67600A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEDE282);
  static const Color onSecondaryContainer = Color(0xFF6C6410);
  static const Color secondaryFixed = Color(0xFFF0E585);
  static const Color secondaryFixedDim = Color(0xFFD3C96C);

  // Tertiary — Rosy Pink
  static const Color tertiary = Color(0xFF874E58);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFDE99A4);
  static const Color onTertiaryContainer = Color(0xFF63303A);
  static const Color tertiaryFixed = Color(0xFFFFD9DE);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Surfaces — warm cream ramp (NO pure white as a background)
  static const Color surface = Color(0xFFFFF8F6); // base background
  static const Color surfaceDim = Color(0xFFEDD5CF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // CARDS
  static const Color surfaceLow = Color(0xFFFFF1ED);
  static const Color surfaceContainer = Color(0xFFFFE9E4);
  static const Color surfaceHigh = Color(0xFFFCE3DD);
  static const Color surfaceHighest = Color(0xFFF6DDD8);
  static const Color onSurface = Color(0xFF251815);
  static const Color onSurfaceVariant = Color(0xFF56423E);

  // Outline
  static const Color outline = Color(0xFF89726D);
  static const Color outlineVariant = Color(0xFFDCC0BA);

  // Inverse
  static const Color inverseSurface = Color(0xFF3C2D29);
  static const Color inverseOnSurface = Color(0xFFFFEDE9);
  static const Color inversePrimary = Color(0xFFFFB4A4);

  // ── Glassmorphism ──────────────────────────────────────────────────────────
  static const Color glassFill = Color(0xD9FFF1ED); // surface-low @ ~85%
  static const double glassBlurSigma = 12.0;

  // ── Elevation glows (peach-tinted, never dark) ──────────────────────────────
  // CSS: 0 8px 30px rgba(255,139,113,.10)
  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x1AFF8B71),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  // CSS: 0 16px 48px -8px rgba(158,65,44,.18)
  static const List<BoxShadow> glowLg = [
    BoxShadow(
      color: Color(0x2E9E412C),
      blurRadius: 48,
      spreadRadius: -8,
      offset: Offset(0, 16),
    ),
  ];

  // CSS: 0 2px 12px rgba(255,139,113,.10)
  static const List<BoxShadow> glowSm = [
    BoxShadow(
      color: Color(0x1AFF8B71),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  // CSS: 0 1px 2px rgba(37,24,21,.04), 0 4px 16px rgba(158,65,44,.06)
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0A251815), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F9E412C), blurRadius: 16, offset: Offset(0, 4)),
  ];

  // Upward glow for sticky bottom nav. CSS: 0 -4px 20px rgba(158,65,44,.08)
  static const List<BoxShadow> navGlow = [
    BoxShadow(color: Color(0x149E412C), blurRadius: 20, offset: Offset(0, -4)),
  ];

  // ── Signature gradients ─────────────────────────────────────────────────────
  // Streak banner: warm "golden hour" sweep (index.html .streak-gradient).
  static const LinearGradient streakGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFFF8B71), Color(0xFFF06B50), Color(0xFFDE7A5E)],
    stops: [0.0, 0.6, 1.0],
  );

  // Glowing primary CTA fill (Peach → Rosy).
  static const LinearGradient primaryGlowGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFFF8B71), Color(0xFF9E412C)],
  );
}
