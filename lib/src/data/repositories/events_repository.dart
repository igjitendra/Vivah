import 'package:drift/drift.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/transaction_enums.dart';
import '../database/app_database.dart';

abstract class EventsRepository {
  Future<List<Event>> getAllActiveEvents();
  Stream<List<Event>> watchActiveEvents();
  Future<List<Event>> getUpcomingEvents();
  Future<List<Event>> getPastEvents();
  Future<List<Event>> searchEvents(String query);
  Future<Event?> getEventById(String id);
  Future<void> createEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> archiveEvent(String id);
}

class DriftEventsRepository implements EventsRepository {
  final AppDatabase _db;

  DriftEventsRepository(this._db);

  @override
  Future<List<Event>> getAllActiveEvents() async {
    final rows = await _db.eventsDao.getAllActiveEvents();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<Event>> watchActiveEvents() {
    return _db.eventsDao.watchActiveEvents().map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<List<Event>> getUpcomingEvents() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db.eventsDao.getUpcomingEvents(today);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<List<Event>> getPastEvents() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db.eventsDao.getPastEvents(today);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final rows = await _db.eventsDao.searchEvents(query);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<Event?> getEventById(String id) async {
    final row = await _db.eventsDao.getEventById(id);
    if (row == null) return null;

    final received = await _db.entriesDao.getEventReceivedTotal(id);
    final given = await _db.entriesDao.getEventGivenTotal(id);
    final count = await _db.eventsDao.countEntriesForEvent(id);

    return _mapToEntity(row, totalReceived: received, totalGiven: given, totalCount: count);
  }

  @override
  Future<void> createEvent(Event event) async {
    await _db.eventsDao.insertEvent(
      EventsCompanion.insert(
        id: event.id,
        title: event.title,
        eventType: event.eventType.labelHindi,
        eventDate: event.eventDate,
        venue: Value(event.venue),
        notes: Value(event.notes),
        createdAt: Value(event.createdAt.toIso8601String()),
        updatedAt: Value(event.updatedAt.toIso8601String()),
      ),
    );
  }

  @override
  Future<void> updateEvent(Event event) async {
    await _db.eventsDao.updateEvent(
      EventsCompanion.insert(
        id: event.id,
        title: event.title,
        eventType: event.eventType.labelHindi,
        eventDate: event.eventDate,
        venue: Value(event.venue),
        notes: Value(event.notes),
        createdAt: Value(event.createdAt.toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Future<void> archiveEvent(String id) async {
    await _db.eventsDao.archiveEvent(id);
  }

  Event _mapToEntity(
    EventRow r, {
    int? totalReceived,
    int? totalGiven,
    int? totalCount,
  }) {
    return Event(
      id: r.id,
      title: r.title,
      eventType: EventType.fromString(r.eventType),
      eventDate: r.eventDate,
      venue: r.venue,
      notes: r.notes,
      createdAt: DateTime.tryParse(r.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r.updatedAt) ?? DateTime.now(),
      archivedAt: r.archivedAt != null ? DateTime.tryParse(r.archivedAt!) : null,
      totalReceivedPaise: totalReceived,
      totalGivenPaise: totalGiven,
      totalEntriesCount: totalCount,
    );
  }
}
