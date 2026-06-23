import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Base text styles with Poppins
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
      );

  static TextStyle get displayMedium => GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
      );

  static TextStyle get displaySmall => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
      );

  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );
}
