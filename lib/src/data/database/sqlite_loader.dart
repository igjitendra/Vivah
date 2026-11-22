import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Configures SQLite native dynamic library loading across all Android versions.
/// Safely handles both extracted and unextracted APK libraries, background isolates,
/// and legacy Android 6-9 linker workarounds.
Future<void> initSqlitePlatform() async {
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    } catch (_) {}
    setupSqliteLoader();
  }
}

/// Fallback-resilient SQLite dynamic library resolver.
/// Ensures dlopen never fails with "libsqlite3.so not found" by trying
/// standard APK dynamic loading, extracted native paths, and process lookup.
@pragma('vm:entry-point')
void setupSqliteLoader() {
  if (kIsWeb || !Platform.isAndroid) return;

  open.overrideFor(OperatingSystem.android, () {
    // 1. Direct dynamic library loading from APK / system (primary for Android 7+)
    try {
      return DynamicLibrary.open('libsqlite3.so');
    } catch (_) {}

    // 2. Extracted private storage library paths (for extracted packaging)
    for (final candidate in [
      '/data/data/com.vyavahaar.vyavahaar/lib/libsqlite3.so',
      '/data/user/0/com.vyavahaar.vyavahaar/lib/libsqlite3.so',
    ]) {
      try {
        return DynamicLibrary.open(candidate);
      } catch (_) {}
    }

    // 3. Process space fallback
    try {
      return DynamicLibrary.process();
    } catch (_) {}

    return DynamicLibrary.executable();
  });
}
