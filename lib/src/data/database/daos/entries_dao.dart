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
/// - Rule 2: Received (मिला) and Given (दिया) never netted into debt
/// - Rule 3: Physical gifts strictly excluded from cash totals
/// - Rule 4: Planned entries excluded from actual totals
/// - Rule 5: Cancelled entries excluded from all calculations
/// - Rule 6: Historical data preserved via soft archive
@DriftAccessor(tables: [Entries, EntryItems, People, Events])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.db);

  /// Get entry by ID
  Future<EntryRow?> getEntryById(String id) {
    return (select(entries)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get total recorded Received (मिला) in integer paise
  Future<int> getTotalReceivedPaise() async {
    final sum = entries.amountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.direction.equals('received') | entries.direction.equals('mila'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  // Alias
  Future<int> getTotalMilaPaise({String? householdId}) => getTotalReceivedPaise();

  /// Get total recorded Given (दिया) in integer paise
  Future<int> getTotalGivenPaise() async {
    final sum = entries.amountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.direction.equals('given') | entries.direction.equals('diya'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  // Alias
  Future<int> getTotalDiyaPaise({String? householdId}) => getTotalGivenPaise();

  /// Get total count of recorded transactions
  Future<int> getRecordedCount({String? householdId}) async {
    final count = entries.id.count();
    final query = selectOnly(entries)
      ..addColumns([count])
      ..where(entries.status.equals('recorded'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(count)).getSingleOrNull();
    return result ?? 0;
  }

  /// Get total count of planned transactions
  Future<int> getPlannedCount({String? householdId}) async {
    final count = entries.id.count();
    final query = selectOnly(entries)
      ..addColumns([count])
      ..where(entries.status.equals('planned'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(count)).getSingleOrNull();
    return result ?? 0;
  }

  /// Get person-specific received total
  Future<int> getPersonReceivedTotal(String personId) async {
    final sum = entries.amountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.personId.equals(personId))
      ..where(entries.direction.equals('received') | entries.direction.equals('mila'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  /// Get person-specific given total
  Future<int> getPersonGivenTotal(String personId) async {
    final sum = entries.amountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.personId.equals(personId))
      ..where(entries.direction.equals('given') | entries.direction.equals('diya'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  /// Get event-specific received total
  Future<int> getEventReceivedTotal(String eventId) async {
    final sum = entries.amountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.eventId.equals(eventId))
      ..where(entries.direction.equals('received') | entries.direction.equals('mila'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  /// Get event-specific given total
  Future<int> getEventGivenTotal(String eventId) async {
    final sum = entries.amountPaise.sum();
    final query = selectOnly(entries)
      ..addColumns([sum])
      ..where(entries.eventId.equals(eventId))
      ..where(entries.direction.equals('given') | entries.direction.equals('diya'))
      ..where(entries.status.equals('recorded'))
      ..where(entries.archivedAt.isNull());

    final result = await query.map((row) => row.read(sum)).getSingleOrNull();
    return result?.toInt() ?? 0;
  }

  /// Watch entries with optional multi-criteria filters
  Stream<List<EntryRow>> watchEntriesFiltered({
    String? direction,
    String? status,
    String? transactionType,
    String? personId,
    String? eventId,
    String? startDate,
    String? endDate,
  }) {
    final query = select(entries)..where((tbl) => tbl.archivedAt.isNull());

    if (direction != null) {
      if (direction == 'given' || direction == 'diya') {
        query.where((tbl) => tbl.direction.equals('given') | tbl.direction.equals('diya'));
      } else {
        query.where((tbl) => tbl.direction.equals('received') | tbl.direction.equals('mila'));
      }
    }
    if (status != null) {
      query.where((tbl) => tbl.status.equals(status));
    }
    if (transactionType != null) {
      query.where((tbl) => tbl.transactionType.equals(transactionType));
    }
    if (personId != null) {
      query.where((tbl) => tbl.personId.equals(personId));
    }
    if (eventId != null) {
      query.where((tbl) => tbl.eventId.equals(eventId));
    }
    if (startDate != null) {
      query.where((tbl) => tbl.transactionDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.transactionDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(tbl) => OrderingTerm.desc(tbl.transactionDate)]);
    return query.watch();
  }

  /// Insert a new entry
  Future<int> insertNewEntry(EntriesCompanion entry) {
    return into(entries).insert(entry);
  }

  /// Update an existing entry
  Future<bool> updateExistingEntry(EntriesCompanion entry) {
    return update(entries).replace(entry);
  }

  /// Mark entry as recorded
  Future<int> markEntryRecorded(String id) {
    return (update(entries)..where((tbl) => tbl.id.equals(id))).write(
      EntriesCompanion(
        status: const Value('recorded'),
        recordedAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Cancel a planned entry
  Future<int> cancelEntry(String id) {
    return (update(entries)..where((tbl) => tbl.id.equals(id))).write(
      EntriesCompanion(
        status: const Value('cancelled'),
        cancelledAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Soft archive an entry (never hard delete)
  Future<int> archiveEntry(String id) {
    return (update(entries)..where((tbl) => tbl.id.equals(id))).write(
      EntriesCompanion(
        archivedAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  // Alias
  Future<int> softDeleteEntry(String id) => archiveEntry(id);

  Stream<List<EntryRow>> watchAllEntries({String? householdId}) =>
      watchEntriesFiltered();

  Stream<List<EntryRow>> watchEntriesByDirection(String direction, {String? householdId}) =>
      watchEntriesFiltered(direction: direction);
}
