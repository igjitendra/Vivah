import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_providers.dart';

/// Supported Settings & UI presentation flavors inspired by InlitX/streak.
enum SettingsVisualStyle {
  express,
  classic;

  static SettingsVisualStyle fromKey(String? raw) {
    if (raw == 'classic') return SettingsVisualStyle.classic;
    return SettingsVisualStyle.express;
  }

  String get storageKey => name;
}

/// Persistent UI preferences (Settings visual style, motion, compact density).
class UiPreferencesState {
  final SettingsVisualStyle style;
  final bool animationsEnabled;
  final bool compactMode;

  const UiPreferencesState({
    this.style = SettingsVisualStyle.express,
    this.animationsEnabled = true,
    this.compactMode = false,
  });

  bool get isExpressStyle => style == SettingsVisualStyle.express;
  bool get isClassicStyle => style == SettingsVisualStyle.classic;

  UiPreferencesState copyWith({
    SettingsVisualStyle? style,
    bool? animationsEnabled,
    bool? compactMode,
  }) {
    return UiPreferencesState(
      style: style ?? this.style,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiPreferencesState &&
          other.style == style &&
          other.animationsEnabled == animationsEnabled &&
          other.compactMode == compactMode;

  @override
  int get hashCode => Object.hash(style, animationsEnabled, compactMode);
}

/// Riverpod notifier persisting UI style, motion, and density preferences in SQLite.
class UiPreferencesNotifier extends StateNotifier<UiPreferencesState> {
  static const String _styleKey = 'ui_settings_style';
  static const String _animationsKey = 'ui_animations_enabled';
  static const String _compactKey = 'ui_compact_mode';

  final Ref _ref;

  UiPreferencesNotifier(this._ref) : super(const UiPreferencesState()) {
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final repo = _ref.read(settingsRepositoryProvider);
      final savedStyle = await repo.getSetting(_styleKey);
      final savedAnimations = await repo.getSetting(_animationsKey);
      final savedCompact = await repo.getSetting(_compactKey);

      state = state.copyWith(
        style: SettingsVisualStyle.fromKey(savedStyle),
        animationsEnabled: savedAnimations == null
            ? state.animationsEnabled
            : savedAnimations != 'false',
        compactMode: savedCompact == null
            ? state.compactMode
            : savedCompact == 'true',
      );
    } catch (_) {}
  }

  Future<void> setStyle(SettingsVisualStyle style) async {
    if (state.style == style) return;
    state = state.copyWith(style: style);
    try {
      await _ref
          .read(settingsRepositoryProvider)
          .setSetting(_styleKey, style.storageKey);
    } catch (_) {}
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    if (state.animationsEnabled == enabled) return;
    state = state.copyWith(animationsEnabled: enabled);
    try {
      await _ref
          .read(settingsRepositoryProvider)
          .setSetting(_animationsKey, enabled.toString());
    } catch (_) {}
  }

  Future<void> setCompactMode(bool compact) async {
    if (state.compactMode == compact) return;
    state = state.copyWith(compactMode: compact);
    try {
      await _ref
          .read(settingsRepositoryProvider)
          .setSetting(_compactKey, compact.toString());
    } catch (_) {}
  }
}

final uiPreferencesProvider =
    StateNotifierProvider<UiPreferencesNotifier, UiPreferencesState>((ref) {
  return UiPreferencesNotifier(ref);
});
