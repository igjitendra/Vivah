import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/core/theme/app_semantic_colors.dart';
import 'package:vyavahaar/src/core/theme/theme_palette.dart';

void main() {
  group('AppSemanticColors Dynamic Derivation', () {
    test('derives valid contrasting semantic tokens across all 25 palettes', () {
      final allPalettes = [
        ...ThemePalette.lightPalettes,
        ...ThemePalette.darkPalettes,
      ];

      expect(allPalettes.length, 25);

      for (final palette in allPalettes) {
        final semantic = AppSemanticColors.fromPalette(palette);

        // Hero surface & foreground must maintain distinct luminance separation
        final heroLum = semantic.heroStart.computeLuminance();
        final onHeroLum = semantic.onHero.computeLuminance();
        expect(
          (onHeroLum - heroLum).abs() > 0.25,
          isTrue,
          reason: 'Palette ${palette.id} hero foreground contrast too low',
        );

        // Mila and Diya colors must remain strictly distinct
        expect(semantic.mila, isNot(equals(semantic.diya)));
        expect(semantic.milaContainer, isNot(equals(semantic.diyaContainer)));

        // Card surfaces match active palette
        expect(semantic.cardBg, equals(palette.surface));
        expect(semantic.textPrimary, equals(palette.textPrimary));
      }
    });

    test('supports smooth lerp and copyWith transitions between light and dark palettes', () {
      final light = AppSemanticColors.fromPalette(ThemePalette.porcelain);
      final dark = AppSemanticColors.fromPalette(ThemePalette.forest);

      final mid = light.lerp(dark, 0.5);
      expect(mid.heroStart, isNot(equals(light.heroStart)));
      expect(mid.heroStart, isNot(equals(dark.heroStart)));

      final overridden = light.copyWith(cardBg: light.heroStart);
      expect(overridden.cardBg, equals(light.heroStart));
    });
  });
}
