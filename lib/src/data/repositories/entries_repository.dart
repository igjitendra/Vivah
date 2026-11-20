import '../../domain/entities/entities.dart';
import '../../domain/enums/transaction_enums.dart';
import '../database/app_database.dart';

/// Abstract contract for Entries repository
abstract class EntriesRepository {
  Future<DashboardSummary> getDashboardSummary({String? householdId});
  Stream<List<TransactionEntry>> watchEntries({TransactionDirection? direction, String? householdId});
  Future<void> createEntry(TransactionEntry entry);
  Future<void> updateEntry(TransactionEntry entry);
  Future<void> deleteEntry(String id);
}

/// Implementation of EntriesRepository backed by Drift AppDatabase
class DriftEntriesRepository implements EntriesRepository {
  final AppDatabase _db;

  DriftEntriesRepository(this._db);

  @override
  Future<DashboardSummary> getDashboardSummary({String? householdId}) async {
    final milaPaise = await _db.entriesDao.getTotalMilaPaise(householdId: householdId);
    final diyaPaise = await _db.entriesDao.getTotalDiyaPaise(householdId: householdId);
    final recordedCount = await _db.entriesDao.getRecordedCount(householdId: householdId);
    final plannedCount = await _db.entriesDao.getPlannedCount(householdId: householdId);

    // Count people
    final peopleCount = await (_db.selectOnly(_db.people)..addColumns([_db.people.id.count()]))
        .map((r) => r.read(_db.people.id.count()))
        .getSingleOrNull() ?? 0;

    // Count events
    final eventsCount = await (_db.selectOnly(_db.events)..addColumns([_db.events.id.count()]))
        .map((r) => r.read(_db.events.id.count()))
        .getSingleOrNull() ?? 0;

    // Get most recent event
    final recentEvent = await (_db.select(_db.events)
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)])
          ..limit(1))
        .getSingleOrNull();

    return DashboardSummary(
      totalMilaPaise: milaPaise,
      totalDiyaPaise: diyaPaise,
      totalEntries: recordedCount,
      totalPlannedEntries: plannedCount,
      totalEvents: eventsCount,
      totalPeople: peopleCount,
      recentEventId: recentEvent?.id,
      recentEventTitle: recentEvent?.title,
      recentEventDate: recentEvent?.eventDate,
    );
  }

  @override
  Stream<List<TransactionEntry>> watchEntries({
    TransactionDirection? direction,
    String? householdId,
  }) {
    final stream = direction != null
        ? _db.entriesDao.watchEntriesByDirection(direction.value, householdId: householdId)
        : _db.entriesDao.watchAllEntries(householdId: householdId);

    return stream.map((rows) => rows.map((r) => _mapToEntity(r)).toList());
  }

  @override
  Future<void> createEntry(TransactionEntry entry) async {
    await _db.entriesDao.insertNewEntry(
      EntriesCompanion.insert(
        id: entry.id,
        householdId: entry.householdId,
        eventId: entry.eventId,
        personId: entry.personId,
        direction: entry.direction.value,
        cashAmountPaise: Value(BigInt.from(entry.cashAmountPaise)),
        status: Value(entry.status.value),
        expectedDate: Value(entry.expectedDate),
        notes: Value(entry.notes),
        createdAt: Value(entry.createdAt.toIso8601String()),
        updatedAt: Value(entry.updatedAt.toIso8601String()),
      ),
    );
  }

  @override
  Future<void> updateEntry(TransactionEntry entry) async {
    await _db.entriesDao.updateExistingEntry(
      EntriesCompanion.insert(
        id: entry.id,
        householdId: entry.householdId,
        eventId: entry.eventId,
        personId: entry.personId,
        direction: entry.direction.value,
        cashAmountPaise: Value(BigInt.from(entry.cashAmountPaise)),
        status: Value(entry.status.value),
        expectedDate: Value(entry.expectedDate),
        notes: Value(entry.notes),
        createdAt: Value(entry.createdAt.toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _db.entriesDao.softDeleteEntry(id);
  }

  TransactionEntry _mapToEntity(Entry r) {
    return TransactionEntry(
      id: r.id,
      householdId: r.householdId,
      eventId: r.eventId,
      personId: r.personId,
      direction: r.direction == 'mila' ? TransactionDirection.mila : TransactionDirection.diya,
      cashAmountPaise: r.cashAmountPaise.toInt(),
      status: TransactionStatus.fromString(r.status),
      expectedDate: r.expectedDate,
      notes: r.notes,
      createdAt: DateTime.tryParse(r.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r.updatedAt) ?? DateTime.now(),
      deletedAt: r.deletedAt != null ? DateTime.tryParse(r.deletedAt!) : null,
    );
  }
}
