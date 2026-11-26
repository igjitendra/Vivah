import 'dart:ffi';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sq;
import 'package:vyavahaar/src/data/database/app_database.dart';
import 'package:vyavahaar/src/data/database/migrations/schema_migrations.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';

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

  group('People Schema Migration & UPSERT Integrity', () {
    test('creates extended columns and updates person in-place without FK cascade deletion', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final now = DateTime.now();
      final person = Person(
        id: 'p-upsert-1',
        fullName: 'सुरेश शर्मा',
        firstName: 'सुरेश',
        lastName: 'शर्मा',
        phoneNumber: '+918787251211',
        secondaryPhones: const ['+919999888877', '+919999888877'],
        whatsappNumber: '+918787251211',
        emails: const ['suresh@example.com'],
        village: 'अयोध्या',
        contactSource: 'phone_import',
        externalContactId: 'ext-1',
        importedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Insert extended person cleanly
      await db.peopleDao.saveExtendedPerson(person);
      final fetched = await db.peopleDao.getPersonById('p-upsert-1');
      expect(fetched, isNotNull);
      expect(fetched!.fullName, equals('सुरेश शर्मा'));

      final ext = await db.peopleDao.getExtendedColumns('p-upsert-1');
      expect(ext, isNotNull);
      expect(ext!['first_name'], equals('सुरेश'));
      expect(ext['contact_source'], equals('phone_import'));

      // Verify deduplicated secondary phones
      final secPhones = await db.peopleDao.getPersonSecondaryPhones('p-upsert-1');
      expect(secPhones, equals(['+919999888877']));

      // 2. Attach a financial entry referencing this person
      await db.into(db.entries).insert(
            EntriesCompanion.insert(
              id: 'e-ref-1',
              personId: 'p-upsert-1',
              direction: 'received',
              amountPaise: Value(BigInt.from(510000)),
              transactionDate: '2026-11-26',
            ),
          );

      // 3. Update / Merge person via saveExtendedPerson (ON CONFLICT DO UPDATE)
      final updated = Person(
        id: 'p-upsert-1',
        fullName: 'सुरेश चंद्र शर्मा',
        firstName: 'सुरेश',
        lastName: 'शर्मा',
        phoneNumber: '+918787251211',
        village: 'फैजाबाद',
        contactSource: 'phone_import',
        createdAt: now,
        updatedAt: DateTime.now(),
      );
      await db.peopleDao.saveExtendedPerson(updated);

      // 4. Verify transaction entry still exists untouched (NOT deleted by REPLACE)
      final entriesCount = await db.peopleDao.countEntriesForPerson('p-upsert-1');
      expect(entriesCount, equals(1));

      final extAfter = await db.peopleDao.getExtendedColumns('p-upsert-1');
      expect(extAfter!['village'], equals('फैजाबाद'));
      expect(SchemaMigrations.currentSchemaVersion, greaterThanOrEqualTo(8));
    });

    test('repairs legacy people table missing first_name even when user_version is already current', () async {
      final rawDb = sq.sqlite3.openInMemory();
      // Simulate broken legacy DB missing extended v6 columns even at user_version = current
      rawDb.execute('''
        CREATE TABLE families (id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, description TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT);
        CREATE TABLE people (id TEXT PRIMARY KEY NOT NULL, family_id TEXT, full_name TEXT NOT NULL, phone_number TEXT, relationship_label TEXT, address TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT);
        CREATE TABLE events (id TEXT PRIMARY KEY NOT NULL, title TEXT NOT NULL, event_type TEXT NOT NULL, event_date TEXT NOT NULL, venue TEXT, household_id TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT);
        CREATE TABLE entries (id TEXT PRIMARY KEY NOT NULL, person_id TEXT NOT NULL, event_id TEXT, direction TEXT NOT NULL, transaction_type TEXT NOT NULL DEFAULT 'cash', status TEXT NOT NULL DEFAULT 'recorded', amount_paise INTEGER, transaction_date TEXT NOT NULL, expected_date TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, recorded_at TEXT, cancelled_at TEXT, archived_at TEXT);
        CREATE TABLE entry_items (id TEXT PRIMARY KEY NOT NULL, entry_id TEXT NOT NULL, item_name TEXT NOT NULL, quantity REAL NOT NULL DEFAULT 1.0, unit TEXT, estimated_value_paise INTEGER, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
        CREATE TABLE reminders (id TEXT PRIMARY KEY NOT NULL, entry_id TEXT, reminder_date TEXT NOT NULL, title TEXT NOT NULL, notes TEXT, is_completed INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
      ''');
      rawDb.execute('PRAGMA user_version = ${SchemaMigrations.currentSchemaVersion};');

      final db = AppDatabase(NativeDatabase.opened(rawDb));
      addTearDown(() async => db.close());

      final now = DateTime.now();
      await db.peopleDao.saveExtendedPerson(
        Person(
          id: 'p-repaired-1',
          fullName: 'रिपेयर टेस्ट',
          firstName: 'रिपेयर',
          phoneNumber: '+918787251211',
          contactSource: 'phone_import',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final ext = await db.peopleDao.getExtendedColumns('p-repaired-1');
      expect(ext, isNotNull);
      expect(ext!['first_name'], equals('रिपेयर'));
    });
  });
}
