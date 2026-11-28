import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_palette.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/express_type.dart';

/// Centralized Material 3 Dynamic Theme Builder for व्यवहार (Vyavahaar)
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => fromPalette(ThemePalette.porcelain);
  static ThemeData get darkTheme => fromPalette(ThemePalette.midnightAurora);

  /// Computes a high-contrast transparent system bar overlay style from the
  /// actual [topBackground] (status bar) and [bottomBackground] (navigation bar).
  static SystemUiOverlayStyle overlayStyleFor({
    required Color topBackground,
    required Color bottomBackground,
  }) {
    final bool topIsDark =
        ThemeData.estimateBrightnessForColor(topBackground) == Brightness.dark;
    final bool bottomIsDark =
        ThemeData.estimateBrightnessForColor(bottomBackground) == Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: topIsDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: topIsDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          bottomIsDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  static const List<String> fontFallbacks = [
    'Poppins',
    'Figtree',
    'NotoSansDevanagari',
    'sans-serif',
  ];

  static ThemeData fromPalette(ThemePalette palette, {Locale? locale}) {
    final brightness = palette.isDark ? Brightness.dark : Brightness.light;
    final isEnglish = locale?.languageCode == 'en';
    final primaryFamily = isEnglish ? 'Figtree' : 'Poppins';
    final semantic = AppSemanticColors.fromPalette(palette);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [semantic],
      textTheme: ExpressType.theme(palette.textPrimary, locale: locale),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: semantic.onVibrant,
        secondary: palette.secondary,
        onSecondary: semantic.onVibrant,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: semantic.diya,
        onError: semantic.onVibrant,
      ),
      scaffoldBackgroundColor: palette.background,
      fontFamily: primaryFamily,
      fontFamilyFallback: fontFallbacks,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        systemOverlayStyle: overlayStyleFor(
          topBackground: palette.surface,
          bottomBackground: palette.background,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: palette.textPrimary, size: 22),
        shape: Border(
          bottom: BorderSide(
            color: palette.cardBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        titleTextStyle: TextStyle(
          fontFamily: primaryFamily,
          fontFamilyFallback: fontFallbacks,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: palette.isDark ? 0 : 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedCard,
          side: BorderSide(color: palette.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: TextStyle(
            fontFamily: primaryFamily,
            fontFamilyFallback: fontFallbacks,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.diyaRed),
        ),
      ),
    );
  }
}
