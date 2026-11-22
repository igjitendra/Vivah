import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_providers.dart';
import 'theme_palette.dart';

class ThemeState {
  final ThemeMode themeMode;
  final ThemePalette lightPalette;
  final ThemePalette darkPalette;

  const ThemeState({
    required this.themeMode,
    required this.lightPalette,
    required this.darkPalette,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    ThemePalette? lightPalette,
    ThemePalette? darkPalette,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      lightPalette: lightPalette ?? this.lightPalette,
      darkPalette: darkPalette ?? this.darkPalette,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final Ref _ref;

  ThemeNotifier(this._ref)
      : super(
          const ThemeState(
            themeMode: ThemeMode.system,
            lightPalette: ThemePalette.porcelain,
            darkPalette: ThemePalette.midnightAurora,
          ),
        ) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      final savedMode = await settingsRepo.getSetting('app_theme_mode');
      final savedLight = await settingsRepo.getSetting('app_theme_light_palette');
      final savedDark = await settingsRepo.getSetting('app_theme_dark_palette');

      ThemeMode mode = state.themeMode;
      if (savedMode == 'light') {
        mode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        mode = ThemeMode.dark;
      } else if (savedMode == 'system') {
        mode = ThemeMode.system;
      }

      final light = savedLight != null ? ThemePalette.getById(savedLight) : state.lightPalette;
      final dark = savedDark != null ? ThemePalette.getById(savedDark, fallbackDark: true) : state.darkPalette;

      state = state.copyWith(
        themeMode: mode,
        lightPalette: light,
        darkPalette: dark,
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final modeStr = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system');
      await _ref.read(settingsRepositoryProvider).setSetting('app_theme_mode', modeStr);
    } catch (_) {}
  }

  Future<void> setLightPalette(ThemePalette palette) async {
    state = state.copyWith(lightPalette: palette);
    try {
      await _ref.read(settingsRepositoryProvider).setSetting('app_theme_light_palette', palette.id);
    } catch (_) {}
  }

  Future<void> setDarkPalette(ThemePalette palette) async {
    state = state.copyWith(darkPalette: palette);
    try {
      await _ref.read(settingsRepositoryProvider).setSetting('app_theme_dark_palette', palette.id);
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier(ref);
});
