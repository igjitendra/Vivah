import 'package:flutter/material.dart';

/// Express Typography Scale directly adapted from InlitX/streak design system.
/// Optimized for authentic Hindi Devanagari (Noto Sans Devanagari) and multilingual Indic scripts.
class ExpressType {
  const ExpressType._();

  static const String devanagariFamily = 'NotoSansDevanagari';

  // --- Display Styles (Splash, Hero Headers, Milestone Cards) ---
  static TextStyle displayLarge({Color? color}) => const TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 57,
        height: 64 / 57,
        letterSpacing: -0.25,
        fontWeight: FontWeight.w900,
      ).copyWith(color: color);

  static TextStyle displayMedium({Color? color}) => const TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 45,
        height: 52 / 45,
        letterSpacing: 0,
        fontWeight: FontWeight.w800,
      ).copyWith(color: color);

  static TextStyle displaySmall({Color? color}) => const TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 36,
        height: 44 / 36,
        letterSpacing: 0,
        fontWeight: FontWeight.w800,
      ).copyWith(color: color);

  // --- Headline Styles (Screen Titles, Modal Headers) ---
  static TextStyle headlineLarge({Color? color, FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 32,
        height: 40 / 32,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle headlineMedium({Color? color, FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 28,
        height: 36 / 28,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle headlineSmall({Color? color, FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 24,
        height: 32 / 24,
        fontWeight: weight,
      ).copyWith(color: color);

  // --- Title Styles (Card Titles, Sections, Prominent Badges) ---
  static TextStyle titleLarge({Color? color, FontWeight weight = FontWeight.w800}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle titleMedium({Color? color, FontWeight weight = FontWeight.w800}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle titleSmall({Color? color, FontWeight weight = FontWeight.w800}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: weight,
      ).copyWith(color: color);

  // --- Body Styles (Paragraphs, List Item Details, Forms) ---
  static TextStyle bodyLarge({Color? color, FontWeight weight = FontWeight.w500}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.5,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle bodyMedium({Color? color, FontWeight weight = FontWeight.w500}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.25,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle bodySmall({Color? color, FontWeight weight = FontWeight.w500}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.4,
        fontWeight: weight,
      ).copyWith(color: color);

  // --- Label Styles (Buttons, Navigation Chips, Badges, Micro-copy) ---
  static TextStyle labelLarge({Color? color, FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle labelMedium({Color? color, FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.5,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle labelSmall({Color? color, FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: devanagariFamily,
        fontSize: 11,
        height: 16 / 11,
        letterSpacing: 0.5,
        fontWeight: weight,
      ).copyWith(color: color);

  /// Builds a complete Material 3 TextTheme utilizing ExpressType definitions
  static TextTheme theme(Color onSurface) {
    return TextTheme(
      displayLarge: displayLarge(color: onSurface),
      displayMedium: displayMedium(color: onSurface),
      displaySmall: displaySmall(color: onSurface),
      headlineLarge: headlineLarge(color: onSurface),
      headlineMedium: headlineMedium(color: onSurface),
      headlineSmall: headlineSmall(color: onSurface),
      titleLarge: titleLarge(color: onSurface),
      titleMedium: titleMedium(color: onSurface),
      titleSmall: titleSmall(color: onSurface),
      bodyLarge: bodyLarge(color: onSurface),
      bodyMedium: bodyMedium(color: onSurface),
      bodySmall: bodySmall(color: onSurface),
      labelLarge: labelLarge(color: onSurface),
      labelMedium: labelMedium(color: onSurface),
      labelSmall: labelSmall(color: onSurface),
    );
  }
}
