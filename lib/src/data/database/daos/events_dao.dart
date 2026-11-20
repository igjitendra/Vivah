import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/events_table.dart';
import '../tables/entries_table.dart';

part 'events_dao.g.dart';

/// DAO for Events table
@DriftAccessor(tables: [Events, Entries])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  /// Get event by ID
  Future<EventRow?> getEventById(String id) {
    return (select(events)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get all active events
  Future<List<EventRow>> getAllActiveEvents() {
    return (select(events)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  /// Watch all active events
  Stream<List<EventRow>> watchActiveEvents() {
    return (select(events)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .watch();
  }

  /// Get upcoming events (event_date >= today)
  Future<List<EventRow>> getUpcomingEvents(String todayIso) {
    return (select(events)
          ..where((t) => t.eventDate.isBiggerOrEqualValue(todayIso) & t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.eventDate)]))
        .get();
  }

  /// Get past events (event_date < today)
  Future<List<EventRow>> getPastEvents(String todayIso) {
    return (select(events)
          ..where((t) => t.eventDate.isSmallerThanValue(todayIso) & t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  /// Search events by title, venue, or event_type
  Future<List<EventRow>> searchEvents(String query) {
    final pattern = '%$query%';
    return (select(events)
          ..where((t) =>
              (t.title.like(pattern) | t.venue.like(pattern) | t.eventType.like(pattern)) &
              t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  /// Insert new event
  Future<int> insertEvent(EventsCompanion event) {
    return into(events).insert(event);
  }

  /// Update event
  Future<bool> updateEvent(EventsCompanion event) {
    return update(events).replace(event);
  }

  /// Soft archive an event
  Future<int> archiveEvent(String id) {
    return (update(events)..where((t) => t.id.equals(id))).write(
      EventsCompanion(
        archivedAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Count transactions associated with this event
  Future<int> countEntriesForEvent(String eventId) async {
    final count = entries.id.count();
    final row = await (selectOnly(entries)
          ..addColumns([count])
          ..where(entries.eventId.equals(eventId) & entries.archivedAt.isNull()))
        .getSingleOrNull();
    return row?.read(count) ?? 0;
  }
}
