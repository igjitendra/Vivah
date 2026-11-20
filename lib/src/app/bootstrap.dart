import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Clean application bootstrap ensuring all asynchronous foundations
/// are initialized before rendering widgets.
Future<void> bootstrap() async {
  // Catch any early synchronous errors
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Configure global error listeners
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (kDebugMode) {
          debugPrint('FlutterError: ${details.exceptionAsString()}');
        }
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        if (kDebugMode) {
          debugPrint('PlatformDispatcher Error: $error\n$stack');
        }
        return true;
      };

      // Run root app wrapped in Riverpod ProviderScope
      runApp(
        const ProviderScope(
          child: VyavahaarApp(),
        ),
      );
    },
    (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Zone Unhandled Error: $error\n$stackTrace');
      }
    },
  );
}
