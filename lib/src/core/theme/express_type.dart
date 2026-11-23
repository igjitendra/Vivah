import 'package:flutter/material.dart';

/// Express Typography Scale directly adapted from InlitX/streak design system.
/// Optimized for authentic Hindi Devanagari (Poppins) and English (Figtree).
class ExpressType {
  const ExpressType._();

  static const String poppinsFamily = 'Poppins';
  static const String figtreeFamily = 'Figtree';
  static const String devanagariFamily = 'Poppins';

  static const List<String> fontFallbacks = [
    'Poppins',
    'Figtree',
    'NotoSansDevanagari',
    'sans-serif',
  ];

  static String familyForLocale([Locale? locale]) {
    if (locale?.languageCode == 'en') {
      return figtreeFamily;
    }
    return poppinsFamily;
  }

  // --- Display Styles (Splash, Hero Headers, Milestone Cards) ---
  static TextStyle displayLarge({Color? color, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 57,
        height: 64 / 57,
        letterSpacing: -0.25,
        fontWeight: FontWeight.w900,
      ).copyWith(color: color);

  static TextStyle displayMedium({Color? color, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 45,
        height: 52 / 45,
        letterSpacing: 0,
        fontWeight: FontWeight.w800,
      ).copyWith(color: color);

  static TextStyle displaySmall({Color? color, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 36,
        height: 44 / 36,
        letterSpacing: 0,
        fontWeight: FontWeight.w800,
      ).copyWith(color: color);

  // --- Headline Styles (Screen Titles, Modal Headers) ---
  static TextStyle headlineLarge({Color? color, FontWeight weight = FontWeight.w700, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 32,
        height: 40 / 32,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle headlineMedium({Color? color, FontWeight weight = FontWeight.w700, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 28,
        height: 36 / 28,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle headlineSmall({Color? color, FontWeight weight = FontWeight.w700, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 24,
        height: 32 / 24,
        fontWeight: weight,
      ).copyWith(color: color);

  // --- Title Styles (Card Titles, Sections, Prominent Badges) ---
  static TextStyle titleLarge({Color? color, FontWeight weight = FontWeight.w800, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle titleMedium({Color? color, FontWeight weight = FontWeight.w800, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle titleSmall({Color? color, FontWeight weight = FontWeight.w800, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: weight,
      ).copyWith(color: color);

  // --- Body Styles (Paragraphs, List Item Details, Forms) ---
  static TextStyle bodyLarge({Color? color, FontWeight weight = FontWeight.w500, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: 0.5,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle bodyMedium({Color? color, FontWeight weight = FontWeight.w500, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.25,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle bodySmall({Color? color, FontWeight weight = FontWeight.w500, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.4,
        fontWeight: weight,
      ).copyWith(color: color);

  // --- Label Styles (Buttons, Navigation Chips, Badges, Micro-copy) ---
  static TextStyle labelLarge({Color? color, FontWeight weight = FontWeight.w700, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.1,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle labelMedium({Color? color, FontWeight weight = FontWeight.w700, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.5,
        fontWeight: weight,
      ).copyWith(color: color);

  static TextStyle labelSmall({Color? color, FontWeight weight = FontWeight.w700, String? fontFamily}) => TextStyle(
        fontFamily: fontFamily ?? devanagariFamily,
        fontFamilyFallback: fontFallbacks,
        fontSize: 11,
        height: 16 / 11,
        letterSpacing: 0.5,
        fontWeight: weight,
      ).copyWith(color: color);

  /// Builds a complete Material 3 TextTheme utilizing ExpressType definitions
  static TextTheme theme(Color onSurface, {Locale? locale}) {
    final family = familyForLocale(locale);
    return TextTheme(
      displayLarge: displayLarge(color: onSurface, fontFamily: family),
      displayMedium: displayMedium(color: onSurface, fontFamily: family),
      displaySmall: displaySmall(color: onSurface, fontFamily: family),
      headlineLarge: headlineLarge(color: onSurface, fontFamily: family),
      headlineMedium: headlineMedium(color: onSurface, fontFamily: family),
      headlineSmall: headlineSmall(color: onSurface, fontFamily: family),
      titleLarge: titleLarge(color: onSurface, fontFamily: family),
      titleMedium: titleMedium(color: onSurface, fontFamily: family),
      titleSmall: titleSmall(color: onSurface, fontFamily: family),
      bodyLarge: bodyLarge(color: onSurface, fontFamily: family),
      bodyMedium: bodyMedium(color: onSurface, fontFamily: family),
      bodySmall: bodySmall(color: onSurface, fontFamily: family),
      labelLarge: labelLarge(color: onSurface, fontFamily: family),
      labelMedium: labelMedium(color: onSurface, fontFamily: family),
      labelSmall: labelSmall(color: onSurface, fontFamily: family),
    );
  }
}
