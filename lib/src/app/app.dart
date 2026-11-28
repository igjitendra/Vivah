import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/theme_notifier.dart';
import '../core/theme/ui_preferences_notifier.dart';
import '../core/localization/locale_notifier.dart';
import '../core/localization/language_registry.dart';
import '../core/localization/app_localizations.dart';
import '../core/shortcuts/app_shortcuts.dart';
import '../core/shortcuts/shortcuts_sheet.dart';

/// Root Application Widget for व्यवहार (Vyavahaar) with dynamic Light/Dark/Auto theme support,
/// complete Indian Multilingual Localization (English + 22 Scheduled Languages), and PC desktop shortcuts.
class VyavahaarApp extends ConsumerStatefulWidget {
  const VyavahaarApp({super.key});

  @override
  ConsumerState<VyavahaarApp> createState() => _VyavahaarAppState();
}

class _VyavahaarAppState extends ConsumerState<VyavahaarApp> {
  @override
  void initState() {
    super.initState();
    AppShortcuts.install();
    AppShortcuts.addListener(_handleShortcut);
  }

  @override
  void dispose() {
    AppShortcuts.removeListener(_handleShortcut);
    super.dispose();
  }

  void _handleShortcut(AppShortcut shortcut) {
    switch (shortcut) {
      case AppShortcut.tab1:
        appRouter.go('/');
        break;
      case AppShortcut.tab2:
        appRouter.go('/bahi');
        break;
      case AppShortcut.tab3:
        appRouter.go('/events');
        break;
      case AppShortcut.tab4:
        appRouter.go('/people');
        break;
      case AppShortcut.tab5:
        appRouter.go('/more');
        break;
      case AppShortcut.newEntry:
        appRouter.push('/entry/new');
        break;
      case AppShortcut.search:
        appRouter.go('/bahi');
        break;
      case AppShortcut.settings:
        appRouter.push('/settings');
        break;
      case AppShortcut.shortcutsHelp:
        final ctx = appRouter.routerDelegate.navigatorKey.currentContext;
        if (ctx != null) ShortcutsSheet.show(ctx);
        break;
      case AppShortcut.escape:
        if (appRouter.canPop()) appRouter.pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final activeLocale = ref.watch(localeProvider);
    final allLanguages = LanguageRegistry.instance.getAllLanguages();
    final supportedLocales = allLanguages.map((lang) => lang.locale).toSet().toList();

    return MaterialApp.router(
      title: activeLocale.languageCode == 'en' ? AppStrings.appNameEnglish : AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: AppTheme.fromPalette(themeState.lightPalette, locale: activeLocale),
      darkTheme: AppTheme.fromPalette(themeState.darkPalette, locale: activeLocale),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            disableAnimations: mq.disableAnimations || !uiPrefs.animationsEnabled,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
