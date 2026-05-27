import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — Vibrant Peach
  static const Color primary = Color(0xFF9E412C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFF8B71);
  static const Color onPrimaryContainer = Color(0xFF752311);

  // Secondary — Soft Lemon
  static const Color secondary = Color(0xFF67600A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEDE282);
  static const Color onSecondaryContainer = Color(0xFF6C6410);

  // Tertiary — Rosy Pink
  static const Color tertiary = Color(0xFF874E58);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFDE99A4);
  static const Color onTertiaryContainer = Color(0xFF63303A);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Surface — Cream
  static const Color surface = Color(0xFFFFF8F6);
  static const Color surfaceContainer = Color(0xFFFFE9E4);
  static const Color onSurface = Color(0xFF251815);
  static const Color onSurfaceVariant = Color(0xFF56423E);

  // Outline
  static const Color outline = Color(0xFF89726D);
  static const Color outlineVariant = Color(0xFFDCC0BA);

  // Inverse
  static const Color inverseSurface = Color(0xFF3C2D29);
  static const Color inverseOnSurface = Color(0xFFFFEDE9);
  static const Color inversePrimary = Color(0xFFFFB4A4);

  // Glassmorphism
  static const Color glassFill = Color(0x99FFFFFF);
  static const double glassBlurSigma = 12.0;
}
