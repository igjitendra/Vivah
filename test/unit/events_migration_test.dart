import 'dart:ffi';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sq;
import 'package:vyavahaar/src/data/database/app_database.dart';
import 'package:vyavahaar/src/data/database/migrations/schema_migrations.dart';
import 'package:vyavahaar/src/data/repositories/events_repository.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';

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

  group('Events Schema v9, Save Persistence & FK Integrity', () {
    test('creates Own Family & Relative events with archived_at = NULL and emits via watchActiveEvents', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repo = DriftEventsRepository(db);
      final now = DateTime.now();

      // Insert a host relative in people table so FK on entries is also testable
      await db.peopleDao.saveExtendedPerson(
        Person(
          id: 'rel-host-1',
          fullName: 'राजेश मामा जी',
          relationshipLabel: 'मामा',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final ownEvent = Event(
        id: 'ev-own-1',
        title: 'शर्मा जी की शादी',
        eventType: EventType.shaadi,
        eventDate: '2026-12-15',
        venue: 'शुभ विवाह भवन',
        villageCity: 'अयोध्या',
        eventScope: EventScope.ownFamily,
        status: EventStatus.planned,
        priority: EventPriority.high,
        budgetEstimatedPaise: 50000000,
        createdAt: now,
        updatedAt: now,
      );

      final relativeEvent = Event(
        id: 'ev-rel-1',
        title: 'मामा जी की बेटी का तिलक',
        eventType: EventType.tilak,
        eventDate: '2026-12-20',
        venue: 'गंगा वाटिका',
        villageCity: 'वाराणसी',
        eventScope: EventScope.relative,
        hostPersonId: 'rel-host-1',
        hostPersonName: 'राजेश मामा जी',
        attendingFamilyNote: 'पूरा परिवार',
        status: EventStatus.confirmed,
        priority: EventPriority.normal,
        createdAt: now,
        updatedAt: now,
      );

      await repo.createEvent(ownEvent);
      await repo.createEvent(relativeEvent);

      // Verify raw SQL archived_at is strictly SQL NULL (not empty string '')
      final rawRows = await db.customSelect('SELECT id, archived_at, event_scope, host_person_id FROM events').get();
      expect(rawRows.length, equals(2));
      for (final r in rawRows) {
        expect(r.readNullable<String>('archived_at'), isNull);
      }

      // Verify repository reads and active stream return both events immediately
      final activeList = await repo.getAllActiveEvents();
      expect(activeList.length, equals(2));

      final streamed = await repo.watchActiveEvents().first;
      expect(streamed.length, equals(2));

      final fetchedRel = await repo.getEventById('ev-rel-1');
      expect(fetchedRel, isNotNull);
      expect(fetchedRel!.isRelativeEvent, isTrue);
      expect(fetchedRel.hostPersonId, equals('rel-host-1'));
      expect(fetchedRel.hostPersonName, equals('राजेश मामा जी'));
      expect(fetchedRel.attendingFamilyNote, equals('पूरा परिवार'));

      final fetchedOwn = await repo.getEventById('ev-own-1');
      expect(fetchedOwn, isNotNull);
      expect(fetchedOwn!.isOwnFamilyEvent, isTrue);
    });

    test('updateEvent uses safe ON CONFLICT UPSERT preserving sub-entities & linked entries', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repo = DriftEventsRepository(db);
      final now = DateTime.now();

      await db.peopleDao.saveExtendedPerson(
        Person(id: 'p-1', fullName: 'कमलेश चाचा', createdAt: now, updatedAt: now),
      );

      final event = Event(
        id: 'ev-upd-1',
        title: 'मुंडन संस्कार',
        eventType: EventType.mundan,
        eventDate: '2026-12-10',
        eventScope: EventScope.relative,
        hostPersonId: 'p-1',
        hostPersonName: 'कमलेश चाचा',
        attendingFamilyNote: 'पिताजी, माताजी',
        createdAt: now,
        updatedAt: now,
      );
      await repo.createEvent(event);

      // Attach sub-entities (function, guest with NULL personId, participant with NULL personId/familyId) + entry
      await repo.addFunction(
        EventFunction(
          id: 'fn-1',
          eventId: 'ev-upd-1',
          title: 'पूजन एवं भोज',
          functionDate: '2026-12-10',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.addGuest(
        EventGuest(
          id: 'g-1',
          eventId: 'ev-upd-1',
          personId: null,
          name: 'अतिथि परिवार',
          createdAt: now,
        ),
      );
      await repo.addParticipant(
        EventParticipant(
          id: 'pt-1',
          eventId: 'ev-upd-1',
          personId: null,
          familyId: null,
          name: 'पंडित जी',
          role: ParticipantRole.organizer,
          createdAt: now,
        ),
      );
      await db.into(db.entries).insert(
            EntriesCompanion.insert(
              id: 'entry-ev-1',
              personId: 'p-1',
              eventId: const Value('ev-upd-1'),
              direction: 'given',
              amountPaise: Value(BigInt.from(210000)),
              transactionDate: '2026-12-10',
            ),
          );

      // Update event (and switch scope from relative to ownFamily clearing host info)
      final updated = event.copyWith(
        title: 'मुंडन एवं भोज कार्यक्रम',
        eventScope: EventScope.ownFamily,
        clearHostInfo: true,
        updatedAt: DateTime.now(),
      );
      await repo.updateEvent(updated);

      final reloaded = await repo.getEventById('ev-upd-1');
      expect(reloaded, isNotNull);
      expect(reloaded!.title, equals('मुंडन एवं भोज कार्यक्रम'));
      expect(reloaded.isOwnFamilyEvent, isTrue);
      expect(reloaded.hostPersonId, isNull);
      expect(reloaded.hostPersonName, isNull);
      expect(reloaded.attendingFamilyNote, isNull);
      expect(reloaded.functions.length, equals(1));
      expect(reloaded.guests.length, equals(1));
      expect(reloaded.participants.length, equals(1));

      // Linked entry must still retain event_id = 'ev-upd-1'
      final linkedEntries = await db.customSelect("SELECT event_id FROM entries WHERE id = 'entry-ev-1'").get();
      expect(linkedEntries.single.readNullable<String>('event_id'), equals('ev-upd-1'));
    });

    test('v9 migration repairs legacy empty-string archived_at rows and adds scope columns', () async {
      final rawDb = sq.sqlite3.openInMemory();
      rawDb.execute('''
        CREATE TABLE families (id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL, description TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT);
        CREATE TABLE people (id TEXT PRIMARY KEY NOT NULL, family_id TEXT, full_name TEXT NOT NULL, phone_number TEXT, relationship_label TEXT, address TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT);
        CREATE TABLE events (id TEXT PRIMARY KEY NOT NULL, title TEXT NOT NULL, event_type TEXT NOT NULL, event_date TEXT NOT NULL, venue TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT);
        CREATE TABLE entries (id TEXT PRIMARY KEY NOT NULL, person_id TEXT NOT NULL, event_id TEXT, direction TEXT NOT NULL, transaction_type TEXT NOT NULL DEFAULT 'cash', status TEXT NOT NULL DEFAULT 'recorded', amount_paise INTEGER, transaction_date TEXT NOT NULL, expected_date TEXT, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, recorded_at TEXT, cancelled_at TEXT, archived_at TEXT);
        CREATE TABLE entry_items (id TEXT PRIMARY KEY NOT NULL, entry_id TEXT NOT NULL, item_name TEXT NOT NULL, quantity REAL NOT NULL DEFAULT 1.0, unit TEXT, estimated_value_paise INTEGER, notes TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
        CREATE TABLE reminders (id TEXT PRIMARY KEY NOT NULL, entry_id TEXT, reminder_date TEXT NOT NULL, title TEXT NOT NULL, notes TEXT, is_completed INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
      ''');
      // Seed an invisible legacy event saved with archived_at = ''
      rawDb.execute('''
        INSERT INTO events (id, title, event_type, event_date, created_at, updated_at, archived_at)
        VALUES ('legacy-ev-1', 'पुरानी शादी', 'shaadi', '2026-12-01', '2026-11-01', '2026-11-01', '');
      ''');
      rawDb.execute('PRAGMA user_version = 8;');

      final db = AppDatabase(NativeDatabase.opened(rawDb));
      addTearDown(() async => db.close());
      final repo = DriftEventsRepository(db);

      final active = await repo.getAllActiveEvents();
      expect(active.length, equals(1));
      expect(active.single.id, equals('legacy-ev-1'));
      expect(active.single.isOwnFamilyEvent, isTrue);
      expect(SchemaMigrations.currentSchemaVersion, greaterThanOrEqualTo(9));
    });
  });
}
