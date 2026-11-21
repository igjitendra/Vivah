import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/theme_notifier.dart';

/// Root Application Widget for व्यवहार (Vyavahaar) with dynamic Light/Dark/Auto theme support
class VyavahaarApp extends ConsumerWidget {
  const VyavahaarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: AppTheme.fromPalette(themeState.lightPalette),
      darkTheme: AppTheme.fromPalette(themeState.darkPalette),
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('hi', 'IN'),
        Locale('en', 'IN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('hi', 'IN'),
    );
  }
}
