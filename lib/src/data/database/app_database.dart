import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'sqlite_loader.dart';

import 'tables/families_table.dart';
import 'tables/people_table.dart';
import 'tables/events_table.dart';
import 'tables/entries_table.dart';
import 'tables/entry_items_table.dart';
import 'tables/reminders_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/attachments_table.dart';

import 'daos/families_dao.dart';
import 'daos/people_dao.dart';
import 'daos/events_dao.dart';
import 'daos/entries_dao.dart';
import 'daos/entry_items_dao.dart';
import 'daos/reminders_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/attachments_dao.dart';

import 'migrations/schema_migrations.dart';

part 'app_database.g.dart';

/// Primary Local Typed Database for Vyavahaar.
/// Works 100% offline across Android, iOS, Linux, macOS, and Windows.
/// Preserves years of family व्यवहार records with zero data loss.
@DriftDatabase(
  tables: [
    Families,
    People,
    Events,
    Entries,
    EntryItems,
    Reminders,
    AppSettings,
    Attachments,
  ],
  daos: [
    FamiliesDao,
    PeopleDao,
    EventsDao,
    EntriesDao,
    EntryItemsDao,
    RemindersDao,
    SettingsDao,
    AttachmentsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  /// In-memory constructor for unit & integration testing
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => SchemaMigrations.currentSchemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await SchemaMigrations.ensureAllTablesAndColumns(this, m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        await SchemaMigrations.migrate(m, this, from, to);
      },
      beforeOpen: (details) async {
        // Enforce Foreign Keys and WAL mode for maximum data integrity across all 5 platforms
        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('PRAGMA journal_mode = WAL;');
        await customStatement('PRAGMA busy_timeout = 5000;');
        if (details.wasCreated || details.hadUpgrade) {
          await SchemaMigrations.ensureAllTablesAndColumns(this, createMigrator());
        }
      },
    );
  }
}

@pragma('vm:entry-point')
void _isolateSetup() {
  setupSqliteLoader();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    setupSqliteLoader();
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vyavahaar.db'));
    return NativeDatabase.createInBackground(
      file,
      isolateSetup: _isolateSetup,
    );
  });
}
