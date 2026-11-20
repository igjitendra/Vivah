import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/households_table.dart';
import 'tables/families_table.dart';
import 'tables/people_table.dart';
import 'tables/events_table.dart';
import 'tables/entries_table.dart';
import 'tables/entry_items_table.dart';
import 'tables/reminders_table.dart';
import 'tables/attachments_table.dart';
import 'daos/entries_dao.dart';

part 'app_database.g.dart';

/// Primary Local Database for Vyavahaar.
/// Works 100% offline across Android, iOS, Linux, macOS, and Windows.
/// Binary-compatible with SQLite database schema version 3.
@DriftDatabase(
  tables: [
    Households,
    Families,
    People,
    Events,
    Entries,
    EntryItems,
    Reminders,
    Attachments,
  ],
  daos: [EntriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create performance indexes matching DATABASE_SCHEMA.md
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_entries_event ON entries(event_id);');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_entries_person ON entries(person_id);');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_entries_direction ON entries(direction);');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_entries_status ON entries(status);');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_people_name ON people(name);');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_people_village ON people(village);');
        await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_entry_items_entry ON entry_items(entry_id);');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          // Schema v3: Add status and expected_date
          await m.addColumn(entries, entries.status);
          await m.addColumn(entries, entries.expectedDate);
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_entries_status ON entries(status);');
        }
      },
      beforeOpen: (details) async {
        // Enforce Foreign Keys and WAL mode for all 5 platforms
        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('PRAGMA journal_mode = WAL;');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vyavahaar.db'));
    return NativeDatabase.createInBackground(file);
  });
}
