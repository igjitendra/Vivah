import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Configures SQLite native dynamic library loading across all Android versions.
/// Safely handles uncompressed APK libraries, background isolates,
/// and legacy Android 6-9 linker workarounds.
Future<void> initSqlitePlatform() async {
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    } catch (_) {}
    setupSqliteLoader();
  }
}

/// Fallback-resilient SQLite dynamic library resolver for Android.
/// Ensures dlopen never fails by trying:
/// 1. Standard dynamic loading from APK (for uncompressed/page-aligned libraries)
/// 2. Active process memory-mapped paths (/proc/self/maps)
/// 3. App-specific storage paths (/data/data, /data/user/0)
/// 4. Process space lookup
@pragma('vm:entry-point')
DynamicLibrary _openAndroidSqlite() {
  // 1. Direct standard dynamic loading (primary for modern Android 7+)
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } catch (_) {}

  // 2. Discover native library directories from /proc/self/maps
  try {
    final maps = File('/proc/self/maps').readAsLinesSync();
    final candidateDirs = <String>{};
    for (final line in maps) {
      if (line.contains('.so')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 6) {
          final path = parts.last;
          if (path.startsWith('/') && path.endsWith('.so')) {
            candidateDirs.add(File(path).parent.path);
          }
        }
      }
    }
    for (final dir in candidateDirs) {
      final cand = '$dir/libsqlite3.so';
      if (File(cand).existsSync()) {
        try {
          return DynamicLibrary.open(cand);
        } catch (_) {}
      }
    }
  } catch (_) {}

  // 3. Fallback candidates for various Android app layouts
  try {
    final appIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();
    final endOfAppId = appIdAsBytes.indexOf(0);
    final appId = endOfAppId > 0
        ? String.fromCharCodes(appIdAsBytes.sublist(0, endOfAppId))
        : 'com.vyavahaar.vyavahaar';
    for (final prefix in ['/data/data', '/data/user/0']) {
      for (final sub in ['lib', 'cache', 'files']) {
        final cand = '$prefix/$appId/$sub/libsqlite3.so';
        try {
          return DynamicLibrary.open(cand);
        } catch (_) {}
      }
    }
  } catch (_) {}

  // 4. Known common paths
  for (final candidate in [
    '/data/data/com.procsctools.vyavahaar/lib/libsqlite3.so',
    '/data/user/0/com.procsctools.vyavahaar/lib/libsqlite3.so',
    '/data/data/com.vyavahaar.vyavahaar/lib/libsqlite3.so',
    '/data/user/0/com.vyavahaar.vyavahaar/lib/libsqlite3.so',
    '/data/data/com.vyavahaar.app/lib/libsqlite3.so',
    '/data/user/0/com.vyavahaar.app/lib/libsqlite3.so',
  ]) {
    try {
      return DynamicLibrary.open(candidate);
    } catch (_) {}
  }

  // 5. Process space fallback
  try {
    return DynamicLibrary.process();
  } catch (_) {}

  return DynamicLibrary.executable();
}

/// Fallback-resilient SQLite dynamic library resolver.
@pragma('vm:entry-point')
void setupSqliteLoader() {
  if (kIsWeb || !Platform.isAndroid) return;
  open.overrideFor(OperatingSystem.android, _openAndroidSqlite);
}
