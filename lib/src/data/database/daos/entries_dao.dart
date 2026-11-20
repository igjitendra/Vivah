import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/entries_table.dart';
import '../tables/entry_items_table.dart';
import '../tables/people_table.dart';
import '../tables/events_table.dart';

part 'entries_dao.g.dart';

/// Data Access Object for Entries (व्यवहार) transactions.
/// Strictly enforces the 12 Financial Rules:
/// - Rule 1: Integer Paise everywhere
/// - Rule 2: Mila and Diya never netted into debt
/// - Rule 3: Physical gifts strictly excluded from cash totals
/// - Rule 4: Planned entries excluded from actual totals
/// - Rule 5: Cancelled entries excluded from all calculations
@DriftAccessor(tables: [Entries, EntryItems, People, Events])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.db);

  /// Get total recorded Mila (received) in integer paise
  Future<int> getTotalMilaPaise({String? householdId}) async {
    final sum = entries.cashAmountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.direction.equals('mila'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.deletedAt.isNull());

    if (householdId != null) {
      query.where(entries.householdId.equals(householdId));
    }

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  /// Get total recorded Diya (given) in integer paise
  Future<int> getTotalDiyaPaise({String? householdId}) async {
    final sum = entries.cashAmountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.direction.equals('diya'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.deletedAt.isNull());

    if (householdId != null) {
      query.where(entries.householdId.equals(householdId));
    }

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  /// Get total count of recorded transactions
  Future<int> getRecordedCount({String? householdId}) async {
    final count = entries.id.count();
    final query = selectOnly(entries)
      ..addColumns([count])
      ..where(entries.status.equals('recorded'))
      ..where(entries.deletedAt.isNull());

    if (householdId != null) {
      query.where(entries.householdId.equals(householdId));
    }

    final result = await query.map((row) => row.read(count)).getSingleOrNull();
    return result ?? 0;
  }

  /// Get total count of planned transactions
  Future<int> getPlannedCount({String? householdId}) async {
    final count = entries.id.count();
    final query = selectOnly(entries)
      ..addColumns([count])
      ..where(entries.status.equals('planned'))
      ..where(entries.deletedAt.isNull());

    if (householdId != null) {
      query.where(entries.householdId.equals(householdId));
    }

    final result = await query.map((row) => row.read(count)).getSingleOrNull();
    return result ?? 0;
  }

  /// Stream all active entries
  Stream<List<Entry>> watchAllEntries({String? householdId}) {
    final query = select(entries)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    if (householdId != null) {
      query.where((tbl) => tbl.householdId.equals(householdId));
    }
    return query.watch();
  }

  /// Stream entries filtered by direction ('mila' or 'diya')
  Stream<List<Entry>> watchEntriesByDirection(String direction, {String? householdId}) {
    final query = select(entries)
      ..where((tbl) => tbl.direction.equals(direction) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    if (householdId != null) {
      query.where((tbl) => tbl.householdId.equals(householdId));
    }
    return query.watch();
  }

  /// Stream entries for an event
  Stream<List<Entry>> watchEntriesForEvent(String eventId) {
    return (select(entries)
          ..where((tbl) => tbl.eventId.equals(eventId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Stream entries for a person
  Stream<List<Entry>> watchEntriesForPerson(String personId) {
    return (select(entries)
          ..where((tbl) => tbl.personId.equals(personId) & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  /// Insert a new entry
  Future<int> insertNewEntry(EntriesCompanion entry) {
    return into(entries).insert(entry);
  }

  /// Update an existing entry
  Future<bool> updateExistingEntry(EntriesCompanion entry) {
    return update(entries).replace(entry);
  }

  /// Soft delete an entry (never hard delete without explicit user intent)
  Future<int> softDeleteEntry(String id) {
    return (update(entries)..where((tbl) => tbl.id.equals(id))).write(
      EntriesCompanion(
        deletedAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
}
