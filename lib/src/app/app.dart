import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../core/constants/app_strings.dart';

/// Root Application Widget for व्यवहार (Vyavahaar)
class VyavahaarApp extends StatelessWidget {
  const VyavahaarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
