import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:vyavahaar/src/core/theme/ui_preferences_notifier.dart';
import 'package:vyavahaar/src/data/database/app_database.dart';
import 'package:vyavahaar/src/data/database/database_module.dart';
import 'package:vyavahaar/src/data/repositories/entries_repository.dart';
import 'package:vyavahaar/src/data/repositories/events_repository.dart';
import 'package:vyavahaar/src/data/repositories/people_repository.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';
import 'package:vyavahaar/src/features/settings/services/backup_service.dart';

void _configureLinuxSqlite() {
  open.overrideFor(OperatingSystem.linux, () {
    for (final path in [
      '/usr/lib/aarch64-linux-gnu/libsqlite3.so.0',
      '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0',
      'libsqlite3.so.0',
      'libsqlite3.so',
    ]) {
      try {
        return DynamicLibrary.open(path);
      } catch (_) {}
    }
    return DynamicLibrary.open('libsqlite3.so');
  });
}

void main() {
  setUpAll(_configureLinuxSqlite);

  group('Streak-Style Settings UI Preferences Persistence', () {
    test('persists style, animations, and compact toggles across sessions', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final c1 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c1.dispose);

      // Allow initial async load to settle
      c1.read(uiPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(c1.read(uiPreferencesProvider).style, SettingsVisualStyle.express);
      expect(c1.read(uiPreferencesProvider).animationsEnabled, isTrue);
      expect(c1.read(uiPreferencesProvider).compactMode, isFalse);

      await c1
          .read(uiPreferencesProvider.notifier)
          .setStyle(SettingsVisualStyle.classic);
      await c1.read(uiPreferencesProvider.notifier).setAnimationsEnabled(false);
      await c1.read(uiPreferencesProvider.notifier).setCompactMode(true);

      // Re-create a fresh container reading from the same persisted SQLite DB
      final c2 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c2.dispose);

      c2.read(uiPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final reloaded = c2.read(uiPreferencesProvider);
      expect(reloaded.style, SettingsVisualStyle.classic);
      expect(reloaded.animationsEnabled, isFalse);
      expect(reloaded.compactMode, isTrue);
    });
  });

  group('Data & Backup Storage Overview Stats', () {
    test('counts active database records and total local image bytes accurately', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final tempDir = Directory.systemTemp.createTempSync('vyavahaar_stats_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      final now = DateTime.now();
      final peopleRepo = DriftPeopleRepository(db);
      final eventsRepo = DriftEventsRepository(db);
      final entriesRepo = DriftEntriesRepository(db);

      await peopleRepo.createPerson(
        Person(
          id: 'p_stat_1',
          fullName: 'रमेश वर्मा',
          relationshipLabel: 'चाचा',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await peopleRepo.createPerson(
        Person(
          id: 'p_stat_archived',
          fullName: 'पुरानी प्रविष्टि',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await peopleRepo.archivePerson('p_stat_archived');

      await eventsRepo.createEvent(
        Event(
          id: 'ev_stat_1',
          title: 'गृह प्रवेश',
          eventType: EventType.grihaPravesh,
          eventDate: '2026-12-01',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await entriesRepo.saveEntryWithItemsAtomic(
        entry: TransactionEntry(
          id: 'ent_stat_1',
          personId: 'p_stat_1',
          eventId: 'ev_stat_1',
          direction: TransactionDirection.received,
          transactionType: TransactionType.cashAndItem,
          status: TransactionStatus.recorded,
          amountPaise: 51000,
          transactionDate: '2026-12-01',
          createdAt: now,
          updatedAt: now,
        ),
        items: [
          EntryItem(
            id: 'it_stat_1',
            entryId: 'ent_stat_1',
            itemName: 'लक्ष्मी गणेश मूर्ति',
            quantity: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final attachDir = Directory(p.join(tempDir.path, 'attachments'))
        ..createSync(recursive: true);
      final familyDir = Directory(p.join(tempDir.path, 'family_profile'))
        ..createSync(recursive: true);

      final sampleBytes1 = Uint8List.fromList(List<int>.filled(2048, 7));
      final sampleBytes2 = Uint8List.fromList(List<int>.filled(1024, 9));
      File(p.join(attachDir.path, 'bill_1.jpg')).writeAsBytesSync(sampleBytes1);
      File(p.join(familyDir.path, 'fam_1.jpg')).writeAsBytesSync(sampleBytes2);

      final stats = await BackupService(db).getStorageOverview(
        overrideBaseDir: tempDir,
      );

      expect(stats.peopleCount, 1);
      expect(stats.eventsCount, 1);
      expect(stats.entriesCount, 1);
      expect(stats.itemsCount, 1);
      expect(stats.photosCount, 2);
      expect(stats.photosTotalBytes, 3072);
    });
  });
}
