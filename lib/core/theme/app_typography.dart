import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Radiant Dew type scale. Quicksand (rounded, friendly) for display/headline/
/// body; Plus Jakarta Sans (structured) for labels/utility. Line-heights and
/// tracking match .../radiant_dew/DESIGN.md exactly. Headlines use slight
/// negative tracking to feel "tight"; labels use positive tracking to scan.
abstract final class AppTypography {
  // height = lineHeight / fontSize ; letterSpacing = em * fontSize

  static TextStyle get displayLg => GoogleFonts.quicksand(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 56 / 48,
        letterSpacing: -0.96, // -0.02em
      );

  static TextStyle get headlineLg => GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
      );

  static TextStyle get headlineMd => GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
      );

  static TextStyle get bodyLg => GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 28 / 18,
      );

  static TextStyle get bodyMd => GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
      );

  static TextStyle get labelMd => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.14, // 0.01em
      );

  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 16 / 12,
        letterSpacing: 0.48, // 0.04em
      );
}
