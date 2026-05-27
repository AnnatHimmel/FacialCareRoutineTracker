import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextStyle get displayLg => GoogleFonts.quicksand(
        fontSize: 48,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineLg => GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineMd => GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLg => GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyMd => GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelMd => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );
}
