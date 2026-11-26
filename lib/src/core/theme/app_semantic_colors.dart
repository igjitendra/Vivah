import 'package:flutter/material.dart';
import 'theme_palette.dart';

/// ThemeExtension providing 100% dynamically derived semantic & surface tokens
/// from any active [ThemePalette]. Eliminates hardcoded color literals across UI widgets.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color heroStart;
  final Color heroEnd;
  final Color onHero;
  final Color onHeroMuted;
  final Color heroHighlight;
  final Color heroCardBg;
  final Color heroCardBorder;

  final Color cardBg;
  final Color cardSubtleBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  final Color primary;
  final Color secondary;
  final Color onVibrant;

  final Color mila;
  final Color milaContainer;
  final Color milaBadgeBg;
  final Color milaBorder;

  final Color diya;
  final Color diyaContainer;
  final Color diyaBadgeBg;
  final Color diyaBorder;

  final Color giftAccent;
  final Color giftContainer;
  final Color cashAccent;
  final Color cashContainer;

  final Color info;
  final Color infoContainer;
  final Color warning;
  final Color warningContainer;

  final Color badgeAlertBg;
  final Color onBadgeAlert;
  final Color shadow;

  const AppSemanticColors({
    required this.heroStart,
    required this.heroEnd,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroHighlight,
    required this.heroCardBg,
    required this.heroCardBorder,
    required this.cardBg,
    required this.cardSubtleBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.secondary,
    required this.onVibrant,
    required this.mila,
    required this.milaContainer,
    required this.milaBadgeBg,
    required this.milaBorder,
    required this.diya,
    required this.diyaContainer,
    required this.diyaBadgeBg,
    required this.diyaBorder,
    required this.giftAccent,
    required this.giftContainer,
    required this.cashAccent,
    required this.cashContainer,
    required this.info,
    required this.infoContainer,
    required this.warning,
    required this.warningContainer,
    required this.badgeAlertBg,
    required this.onBadgeAlert,
    required this.shadow,
  });

  /// Convenience lookup from [BuildContext] with safe fallback.
  static AppSemanticColors of(BuildContext context) {
    final ext = Theme.of(context).extension<AppSemanticColors>();
    if (ext != null) return ext;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppSemanticColors.fromPalette(
      isDark ? ThemePalette.midnightAurora : ThemePalette.porcelain,
    );
  }

  /// Derives every semantic, hero, card, and financial token from [palette].
  factory AppSemanticColors.fromPalette(ThemePalette palette) {
    final bool isDark = palette.isDark;

    // Derive rich hero header tones from the palette's secondary & primary hues.
    final HSLColor secondaryHsl = HSLColor.fromColor(palette.secondary);
    final Color richHeroStart = isDark
        ? Color.lerp(palette.surface, palette.primary, 0.24)!
        : secondaryHsl
            .withLightness(secondaryHsl.lightness.clamp(0.14, 0.24))
            .withSaturation((secondaryHsl.saturation * 1.08).clamp(0.25, 0.85))
            .toColor();
    final Color richHeroEnd = isDark
        ? Color.lerp(palette.background, palette.secondary, 0.22)!
        : HSLColor.fromColor(richHeroStart)
            .withLightness((HSLColor.fromColor(richHeroStart).lightness - 0.05).clamp(0.08, 0.19))
            .toColor();

    final Color onHero = isDark ? palette.textPrimary : palette.surface;
    final Color onHeroMuted = onHero.withValues(alpha: 0.78);

    // Warm cream / luminous highlight derived from palette background + primary for titles on hero.
    final Color blendedHighlight = Color.lerp(palette.background, palette.primary, 0.35)!;
    final HSLColor highlightHsl = HSLColor.fromColor(blendedHighlight);
    final Color heroHighlight = highlightHsl
        .withLightness(highlightHsl.lightness.clamp(0.78, 0.90))
        .withSaturation((highlightHsl.saturation * 1.15).clamp(0.35, 0.85))
        .toColor();

    // Overlapping family card surface tinted gently from the palette.
    final Color warmTint = Color.lerp(palette.background, palette.primary, 0.16)!;
    final Color heroCardBg = isDark
        ? Color.lerp(palette.surface, palette.primary, 0.14)!
        : Color.lerp(palette.surface, warmTint, 0.65)!;
    final Color heroCardBorder = Color.lerp(palette.cardBorder, palette.primary, 0.35)!;

    // Semantic financial hues adjusted cleanly for light vs dark backgrounds.
    final Color milaBase = _harmonizedHue(
      base: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
      paletteAnchor: palette.primary,
      amount: 0.06,
    );
    final Color diyaBase = _harmonizedHue(
      base: isDark ? const Color(0xFFF87171) : const Color(0xFFC81E1E),
      paletteAnchor: palette.primary,
      amount: 0.06,
    );
    final Color infoBase = _harmonizedHue(
      base: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      paletteAnchor: palette.primary,
      amount: 0.12,
    );
    final Color warningBase = _harmonizedHue(
      base: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      paletteAnchor: palette.primary,
      amount: 0.10,
    );

    final Color giftAccent = Color.lerp(infoBase, palette.primary, 0.22)!;
    final Color cashAccent = Color.lerp(warningBase, milaBase, 0.18)!;

    final Color onVibrant = isDark ? palette.background : palette.surface;
    final Color badgeAlertBg = diyaBase;
    final Color onBadgeAlert = isDark ? palette.background : palette.surface;

    return AppSemanticColors(
      heroStart: richHeroStart,
      heroEnd: richHeroEnd,
      onHero: onHero,
      onHeroMuted: onHeroMuted,
      heroHighlight: heroHighlight,
      heroCardBg: heroCardBg,
      heroCardBorder: heroCardBorder,
      cardBg: palette.surface,
      cardSubtleBg: Color.lerp(palette.surface, palette.background, isDark ? 0.40 : 0.60)!,
      cardBorder: palette.cardBorder,
      textPrimary: palette.textPrimary,
      textSecondary: palette.textSecondary,
      primary: palette.primary,
      secondary: palette.secondary,
      onVibrant: onVibrant,
      mila: milaBase,
      milaContainer: Color.lerp(palette.surface, milaBase, isDark ? 0.22 : 0.10)!,
      milaBadgeBg: Color.lerp(palette.surface, milaBase, isDark ? 0.30 : 0.16)!,
      milaBorder: milaBase.withValues(alpha: isDark ? 0.45 : 0.28),
      diya: diyaBase,
      diyaContainer: Color.lerp(palette.surface, diyaBase, isDark ? 0.22 : 0.10)!,
      diyaBadgeBg: Color.lerp(palette.surface, diyaBase, isDark ? 0.30 : 0.16)!,
      diyaBorder: diyaBase.withValues(alpha: isDark ? 0.45 : 0.26),
      giftAccent: giftAccent,
      giftContainer: Color.lerp(palette.surface, giftAccent, isDark ? 0.20 : 0.10)!,
      cashAccent: cashAccent,
      cashContainer: Color.lerp(palette.surface, cashAccent, isDark ? 0.20 : 0.11)!,
      info: infoBase,
      infoContainer: Color.lerp(palette.surface, infoBase, isDark ? 0.22 : 0.11)!,
      warning: warningBase,
      warningContainer: Color.lerp(palette.surface, warningBase, isDark ? 0.22 : 0.12)!,
      badgeAlertBg: badgeAlertBg,
      onBadgeAlert: onBadgeAlert,
      shadow: palette.textPrimary.withValues(alpha: isDark ? 0.36 : 0.08),
    );
  }

  static Color _harmonizedHue({
    required Color base,
    required Color paletteAnchor,
    required double amount,
  }) {
    return Color.lerp(base, paletteAnchor, amount) ?? base;
  }

  @override
  AppSemanticColors copyWith({
    Color? heroStart,
    Color? heroEnd,
    Color? onHero,
    Color? onHeroMuted,
    Color? heroHighlight,
    Color? heroCardBg,
    Color? heroCardBorder,
    Color? cardBg,
    Color? cardSubtleBg,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? secondary,
    Color? onVibrant,
    Color? mila,
    Color? milaContainer,
    Color? milaBadgeBg,
    Color? milaBorder,
    Color? diya,
    Color? diyaContainer,
    Color? diyaBadgeBg,
    Color? diyaBorder,
    Color? giftAccent,
    Color? giftContainer,
    Color? cashAccent,
    Color? cashContainer,
    Color? info,
    Color? infoContainer,
    Color? warning,
    Color? warningContainer,
    Color? badgeAlertBg,
    Color? onBadgeAlert,
    Color? shadow,
  }) {
    return AppSemanticColors(
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      heroHighlight: heroHighlight ?? this.heroHighlight,
      heroCardBg: heroCardBg ?? this.heroCardBg,
      heroCardBorder: heroCardBorder ?? this.heroCardBorder,
      cardBg: cardBg ?? this.cardBg,
      cardSubtleBg: cardSubtleBg ?? this.cardSubtleBg,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      onVibrant: onVibrant ?? this.onVibrant,
      mila: mila ?? this.mila,
      milaContainer: milaContainer ?? this.milaContainer,
      milaBadgeBg: milaBadgeBg ?? this.milaBadgeBg,
      milaBorder: milaBorder ?? this.milaBorder,
      diya: diya ?? this.diya,
      diyaContainer: diyaContainer ?? this.diyaContainer,
      diyaBadgeBg: diyaBadgeBg ?? this.diyaBadgeBg,
      diyaBorder: diyaBorder ?? this.diyaBorder,
      giftAccent: giftAccent ?? this.giftAccent,
      giftContainer: giftContainer ?? this.giftContainer,
      cashAccent: cashAccent ?? this.cashAccent,
      cashContainer: cashContainer ?? this.cashContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      badgeAlertBg: badgeAlertBg ?? this.badgeAlertBg,
      onBadgeAlert: onBadgeAlert ?? this.onBadgeAlert,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      heroHighlight: Color.lerp(heroHighlight, other.heroHighlight, t)!,
      heroCardBg: Color.lerp(heroCardBg, other.heroCardBg, t)!,
      heroCardBorder: Color.lerp(heroCardBorder, other.heroCardBorder, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardSubtleBg: Color.lerp(cardSubtleBg, other.cardSubtleBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onVibrant: Color.lerp(onVibrant, other.onVibrant, t)!,
      mila: Color.lerp(mila, other.mila, t)!,
      milaContainer: Color.lerp(milaContainer, other.milaContainer, t)!,
      milaBadgeBg: Color.lerp(milaBadgeBg, other.milaBadgeBg, t)!,
      milaBorder: Color.lerp(milaBorder, other.milaBorder, t)!,
      diya: Color.lerp(diya, other.diya, t)!,
      diyaContainer: Color.lerp(diyaContainer, other.diyaContainer, t)!,
      diyaBadgeBg: Color.lerp(diyaBadgeBg, other.diyaBadgeBg, t)!,
      diyaBorder: Color.lerp(diyaBorder, other.diyaBorder, t)!,
      giftAccent: Color.lerp(giftAccent, other.giftAccent, t)!,
      giftContainer: Color.lerp(giftContainer, other.giftContainer, t)!,
      cashAccent: Color.lerp(cashAccent, other.cashAccent, t)!,
      cashContainer: Color.lerp(cashContainer, other.cashContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      badgeAlertBg: Color.lerp(badgeAlertBg, other.badgeAlertBg, t)!,
      onBadgeAlert: Color.lerp(onBadgeAlert, other.onBadgeAlert, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
