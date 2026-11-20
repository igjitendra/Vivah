import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app_providers.dart';
import 'language_registry.dart';
import 'models/language_spec.dart';

/// StateNotifier managing the user's active application Locale.
/// Persists preference via SettingsRepository.
class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;

  LocaleNotifier(this._ref) : super(const Locale('hi', 'IN')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      final savedTag = await settingsRepo.getSetting('preferred_locale_tag');
      if (savedTag != null && savedTag.isNotEmpty) {
        final spec = LanguageRegistry.instance.getLanguage(savedTag);
        if (spec != null) {
          state = spec.locale;
        }
      }
    } catch (_) {
      // Keep default Hindi
    }
  }

  /// Change active locale and persist to settings
  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    try {
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      await settingsRepo.setSetting('preferred_locale_tag', newLocale.toLanguageTag());
    } catch (_) {}
  }

  /// Change by LanguageSpec
  Future<void> setLanguage(LanguageSpec spec) async {
    await setLocale(spec.locale);
  }
}

/// Global provider for active application Locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

/// Provider for active LanguageSpec
final currentLanguageSpecProvider = Provider<LanguageSpec>((ref) {
  final currentLocale = ref.watch(localeProvider);
  return LanguageRegistry.instance.getLanguageByLocale(currentLocale);
});
