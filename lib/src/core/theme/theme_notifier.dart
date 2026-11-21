import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  ThemeNotifier()
      : super(
          const ThemeState(
            themeMode: ThemeMode.system,
            lightPalette: ThemePalette.porcelain,
            darkPalette: ThemePalette.midnightAurora,
          ),
        );

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLightPalette(ThemePalette palette) {
    state = state.copyWith(lightPalette: palette);
  }

  void setDarkPalette(ThemePalette palette) {
    state = state.copyWith(darkPalette: palette);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
