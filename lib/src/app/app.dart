import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/theme_notifier.dart';
import '../core/localization/locale_notifier.dart';
import '../core/localization/language_registry.dart';
import '../core/localization/app_localizations.dart';

/// Root Application Widget for व्यवहार (Vyavahaar) with dynamic Light/Dark/Auto theme support
/// and complete Indian Multilingual Localization (English + 22 Scheduled Languages).
class VyavahaarApp extends ConsumerWidget {
  const VyavahaarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final activeLocale = ref.watch(localeProvider);
    final allLanguages = LanguageRegistry.instance.getAllLanguages();
    final supportedLocales = allLanguages.map((lang) => lang.locale).toSet().toList();

    return MaterialApp.router(
      title: activeLocale.languageCode == 'en' ? AppStrings.appNameEnglish : AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: AppTheme.fromPalette(themeState.lightPalette),
      darkTheme: AppTheme.fromPalette(themeState.darkPalette),
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      locale: activeLocale,
    );
  }
}
