import 'package:drift/drift.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/transaction_enums.dart';
import '../../domain/rules/financial_rules.dart';
import '../database/app_database.dart';

/// Abstract contract for Entries repository
abstract class EntriesRepository {
  Future<DashboardSummary> getDashboardSummary();
  Stream<List<TransactionEntry>> watchEntries({
    TransactionDirection? direction,
    TransactionStatus? status,
    TransactionType? type,
    String? personId,
    String? eventId,
    String? startDate,
    String? endDate,
  });
  Future<TransactionEntry?> getEntryById(String id);
  Future<void> saveEntryWithItemsAtomic({
    required TransactionEntry entry,
    required List<EntryItem> items,
  });
  Future<void> updateEntryWithItemsAtomic({
    required TransactionEntry entry,
    required List<EntryItem> items,
  });
  Future<void> cancelPlannedEntry(String id);
  Future<void> markPlannedEntryRecorded(String id);
  Future<void> archiveEntry(String id);
  Future<Map<String, int>> getPersonHistoryStats(String personId);
  Future<Map<String, int>> getEventHistoryStats(String eventId);
}

/// Implementation of EntriesRepository backed by Drift AppDatabase
class DriftEntriesRepository implements EntriesRepository {
  final AppDatabase _db;

  DriftEntriesRepository(this._db);

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    final receivedPaise = await _db.entriesDao.getTotalReceivedPaise();
    final givenPaise = await _db.entriesDao.getTotalGivenPaise();
    final recordedCount = await _db.entriesDao.getRecordedCount();
    final plannedCount = await _db.entriesDao.getPlannedCount();

    // Count people
    final peopleCount = await (_db.selectOnly(_db.people)
          ..addColumns([_db.people.id.count()])
          ..where(_db.people.archivedAt.isNull()))
        .map((r) => r.read(_db.people.id.count()))
        .getSingleOrNull() ?? 0;

    // Count events
    final eventsCount = await (_db.selectOnly(_db.events)
          ..addColumns([_db.events.id.count()])
          ..where(_db.events.archivedAt.isNull()))
        .map((r) => r.read(_db.events.id.count()))
        .getSingleOrNull() ?? 0;

    // Get most recent event
    final recentEvent = await (_db.select(_db.events)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)])
          ..limit(1))
        .getSingleOrNull();

    return DashboardSummary(
      totalReceivedPaise: receivedPaise,
      totalGivenPaise: givenPaise,
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
    TransactionStatus? status,
    TransactionType? type,
    String? personId,
    String? eventId,
    String? startDate,
    String? endDate,
  }) {
    return _db.entriesDao
        .watchEntriesFiltered(
          direction: direction?.value,
          status: status?.value,
          transactionType: type?.value,
          personId: personId,
          eventId: eventId,
          startDate: startDate,
          endDate: endDate,
        )
        .asyncMap((rows) async {
          final results = <TransactionEntry>[];
          for (final row in rows) {
            final items = await _db.entryItemsDao.getItemsForEntry(row.id);
            final person = await _db.peopleDao.getPersonById(row.personId);
            final event = row.eventId != null
                ? await _db.eventsDao.getEventById(row.eventId!)
                : null;

            results.add(_mapToEntity(row, items, person, event));
          }
          return results;
        });
  }

  @override
  Future<TransactionEntry?> getEntryById(String id) async {
    final row = await _db.entriesDao.getEntryById(id);
    if (row == null) return null;

    final items = await _db.entryItemsDao.getItemsForEntry(id);
    final person = await _db.peopleDao.getPersonById(row.personId);
    final event = row.eventId != null
        ? await _db.eventsDao.getEventById(row.eventId!)
        : null;

    return _mapToEntity(row, items, person, event);
  }

  @override
  Future<void> saveEntryWithItemsAtomic({
    required TransactionEntry entry,
    required List<EntryItem> items,
  }) async {
    // 1. Validate transaction according to domain rules
    FinancialRules.validateTransactionEntry(
      type: entry.transactionType,
      direction: entry.direction,
      status: entry.status,
      amountPaise: entry.amountPaise,
      items: items,
    );

    // 2. Execute atomically inside a SQLite transaction
    await _db.transaction(() async {
      await _db.entriesDao.insertNewEntry(
        EntriesCompanion.insert(
          id: entry.id,
          personId: entry.personId,
          eventId: Value(entry.eventId),
          direction: entry.direction.value,
          transactionType: Value(entry.transactionType.value),
          status: Value(entry.status.value),
          amountPaise: Value(entry.amountPaise != null ? BigInt.from(entry.amountPaise!) : null),
          transactionDate: entry.transactionDate,
          notes: Value(entry.notes),
          createdAt: Value(entry.createdAt.toIso8601String()),
          updatedAt: Value(entry.updatedAt.toIso8601String()),
          recordedAt: Value(entry.recordedAt?.toIso8601String()),
          cancelledAt: Value(entry.cancelledAt?.toIso8601String()),
        ),
      );

      if (items.isNotEmpty) {
        final companions = items.map((item) {
          return EntryItemsCompanion.insert(
            id: item.id,
            entryId: entry.id,
            itemName: item.itemName,
            quantity: Value(item.quantity),
            unit: Value(item.unit),
            estimatedValuePaise: Value(item.estimatedValuePaise != null
                ? BigInt.from(item.estimatedValuePaise!)
                : null),
            notes: Value(item.notes),
            createdAt: Value(item.createdAt.toIso8601String()),
            updatedAt: Value(item.updatedAt.toIso8601String()),
          );
        }).toList();

        await _db.entryItemsDao.insertMultipleItems(companions);
      }
    });
  }

  @override
  Future<void> updateEntryWithItemsAtomic({
    required TransactionEntry entry,
    required List<EntryItem> items,
  }) async {
    FinancialRules.validateTransactionEntry(
      type: entry.transactionType,
      direction: entry.direction,
      status: entry.status,
      amountPaise: entry.amountPaise,
      items: items,
    );

    await _db.transaction(() async {
      await _db.entriesDao.updateExistingEntry(
        EntriesCompanion.insert(
          id: entry.id,
          personId: entry.personId,
          eventId: Value(entry.eventId),
          direction: entry.direction.value,
          transactionType: Value(entry.transactionType.value),
          status: Value(entry.status.value),
          amountPaise: Value(entry.amountPaise != null ? BigInt.from(entry.amountPaise!) : null),
          transactionDate: entry.transactionDate,
          notes: Value(entry.notes),
          createdAt: Value(entry.createdAt.toIso8601String()),
          updatedAt: Value(DateTime.now().toIso8601String()),
          recordedAt: Value(entry.recordedAt?.toIso8601String()),
          cancelledAt: Value(entry.cancelledAt?.toIso8601String()),
        ),
      );

      // Replace items atomically
      await _db.entryItemsDao.deleteItemsForEntry(entry.id);
      if (items.isNotEmpty) {
        final companions = items.map((item) {
          return EntryItemsCompanion.insert(
            id: item.id,
            entryId: entry.id,
            itemName: item.itemName,
            quantity: Value(item.quantity),
            unit: Value(item.unit),
            estimatedValuePaise: Value(item.estimatedValuePaise != null
                ? BigInt.from(item.estimatedValuePaise!)
                : null),
            notes: Value(item.notes),
            createdAt: Value(item.createdAt.toIso8601String()),
            updatedAt: Value(DateTime.now().toIso8601String()),
          );
        }).toList();

        await _db.entryItemsDao.insertMultipleItems(companions);
      }
    });
  }

  @override
  Future<void> cancelPlannedEntry(String id) async {
    await _db.entriesDao.cancelEntry(id);
  }

  @override
  Future<void> markPlannedEntryRecorded(String id) async {
    await _db.entriesDao.markEntryRecorded(id);
  }

  @override
  Future<void> archiveEntry(String id) async {
    await _db.entriesDao.archiveEntry(id);
  }

  @override
  Future<Map<String, int>> getPersonHistoryStats(String personId) async {
    final received = await _db.entriesDao.getPersonReceivedTotal(personId);
    final given = await _db.entriesDao.getPersonGivenTotal(personId);
    return {
      'received_paise': received,
      'given_paise': given,
    };
  }

  @override
  Future<Map<String, int>> getEventHistoryStats(String eventId) async {
    final received = await _db.entriesDao.getEventReceivedTotal(eventId);
    final given = await _db.entriesDao.getEventGivenTotal(eventId);
    return {
      'received_paise': received,
      'given_paise': given,
    };
  }

  TransactionEntry _mapToEntity(
    EntryRow r,
    List<EntryItemRow> itemRows,
    PersonRow? person,
    EventRow? event,
  ) {
    final domainItems = itemRows.map((it) {
      return EntryItem(
        id: it.id,
        entryId: it.entryId,
        itemName: it.itemName,
        quantity: it.quantity,
        unit: it.unit,
        estimatedValuePaise: it.estimatedValuePaise?.toInt(),
        notes: it.notes,
        createdAt: DateTime.tryParse(it.createdAt) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(it.updatedAt) ?? DateTime.now(),
      );
    }).toList();

    return TransactionEntry(
      id: r.id,
      personId: r.personId,
      eventId: r.eventId,
      direction: TransactionDirection.fromString(r.direction),
      transactionType: TransactionType.fromString(r.transactionType),
      status: TransactionStatus.fromString(r.status),
      amountPaise: r.amountPaise?.toInt(),
      transactionDate: r.transactionDate,
      notes: r.notes,
      createdAt: DateTime.tryParse(r.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r.updatedAt) ?? DateTime.now(),
      recordedAt: r.recordedAt != null ? DateTime.tryParse(r.recordedAt!) : null,
      cancelledAt: r.cancelledAt != null ? DateTime.tryParse(r.cancelledAt!) : null,
      archivedAt: r.archivedAt != null ? DateTime.tryParse(r.archivedAt!) : null,
      personName: person?.fullName,
      personAddress: person?.address,
      personRelationship: person?.relationshipLabel,
      eventTitle: event?.title,
      eventDate: event?.eventDate,
      items: domainItems,
    );
  }
}
