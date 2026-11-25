import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/transaction_enums.dart';
import '../database/app_database.dart';

abstract class EventsRepository {
  Future<List<Event>> getAllActiveEvents();
  Stream<List<Event>> watchActiveEvents();
  Stream<List<Event>> watchArchivedEvents();
  Future<List<Event>> getUpcomingEvents();
  Future<List<Event>> getPastEvents();
  Future<List<Event>> searchEvents(String query);
  Future<Event?> getEventById(String id);
  Stream<Event?> watchEventById(String id);
  Future<void> createEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> archiveEvent(String id);
  Future<void> restoreEvent(String id);
  Future<void> cancelEvent(String id, String reason);
  Future<String> duplicateEvent(String sourceEventId, String newTitle, String newDate);
  Future<void> deleteEventSafely(String id);

  // Sub-entity operations
  Future<void> addFunction(EventFunction fn);
  Future<void> updateFunction(EventFunction fn);
  Future<void> deleteFunction(String id);

  Future<void> addTask(EventTask task);
  Future<void> updateTask(EventTask task);
  Future<void> toggleTaskStatus(String id, TaskStatus status);
  Future<void> deleteTask(String id);

  Future<void> addGuest(EventGuest guest);
  Future<void> updateGuest(EventGuest guest);
  Future<void> deleteGuest(String id);

  Future<void> addParticipant(EventParticipant participant);
  Future<void> updateParticipant(EventParticipant participant);
  Future<void> removeParticipant(String id);

  Future<void> addBudgetCategory(EventBudgetCategory cat);
  Future<void> updateBudgetCategory(EventBudgetCategory cat);
  Future<void> deleteBudgetCategory(String id);

  Future<void> addNote(EventNote note);
  Future<void> updateNote(EventNote note);
  Future<void> deleteNote(String id);

  Future<void> addReminder(EventReminder reminder);
  Future<void> toggleReminder(String id, bool isEnabled);
  Future<void> deleteReminder(String id);

  // Conflict detection
  Future<List<String>> detectConflicts(Event event);
}

class DriftEventsRepository implements EventsRepository {
  final AppDatabase _db;

  DriftEventsRepository(this._db);

  @override
  Future<List<Event>> getAllActiveEvents() async {
    final rows = await _db.eventsDao.getAllActiveEvents();
    final list = <Event>[];
    for (final r in rows) {
      final ext = await _db.eventsDao.getExtendedColumns(r.id);
      list.add(_mapToEntity(r, extended: ext));
    }
    return list;
  }

  Future<List<Event>> _hydrateEventsBatch(List<EventRow> rows) async {
    if (rows.isEmpty) return const [];
    return Future.wait(rows.map((r) async {
      final ext = await _db.eventsDao.getExtendedColumns(r.id);
      return _mapToEntity(r, extended: ext);
    }));
  }

  @override
  Stream<List<Event>> watchActiveEvents() {
    return _db.eventsDao.watchActiveEvents().asyncMap(_hydrateEventsBatch);
  }

  @override
  Stream<List<Event>> watchArchivedEvents() {
    return _db.eventsDao.watchArchivedEvents().asyncMap(_hydrateEventsBatch);
  }

  @override
  Future<List<Event>> getUpcomingEvents() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db.eventsDao.getUpcomingEvents(today);
    return _hydrateEventsBatch(rows);
  }

  @override
  Future<List<Event>> getPastEvents() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db.eventsDao.getPastEvents(today);
    return _hydrateEventsBatch(rows);
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final rows = await _db.eventsDao.searchEvents(query);
    return _hydrateEventsBatch(rows);
  }

  @override
  Future<Event?> getEventById(String id) async {
    final row = await _db.eventsDao.getEventById(id);
    if (row == null) return null;

    final results = await Future.wait([
      _db.entriesDao.getEventReceivedTotal(id),
      _db.entriesDao.getEventGivenTotal(id),
      _db.eventsDao.countEntriesForEvent(id),
      _db.eventsDao.getExtendedColumns(id),
      _db.eventsDao.getFunctionsForEvent(id),
      _db.eventsDao.getParticipantsForEvent(id),
      _db.eventsDao.getGuestsForEvent(id),
      _db.eventsDao.getTasksForEvent(id),
      _db.eventsDao.getScheduleForEvent(id),
      _db.eventsDao.getBudgetCategoriesForEvent(id),
      _db.eventsDao.getNotesForEvent(id),
      _db.eventsDao.getAttachmentsForEvent(id),
      _db.eventsDao.getActivityLogsForEvent(id),
      _db.eventsDao.getRemindersForEvent(id),
    ]);

    return _mapToEntity(
      row,
      totalReceived: results[0] as int,
      totalGiven: results[1] as int,
      totalCount: results[2] as int,
      extended: (results[3] as Map<String, dynamic>?) ?? const {},
      functions: (results[4] as List<EventFunction>?) ?? const [],
      participants: (results[5] as List<EventParticipant>?) ?? const [],
      guests: (results[6] as List<EventGuest>?) ?? const [],
      tasks: (results[7] as List<EventTask>?) ?? const [],
      schedule: (results[8] as List<EventScheduleItem>?) ?? const [],
      budgetCategories: (results[9] as List<EventBudgetCategory>?) ?? const [],
      notes: (results[10] as List<EventNote>?) ?? const [],
      attachments: (results[11] as List<EventAttachment>?) ?? const [],
      activityLogs: (results[12] as List<EventActivityLog>?) ?? const [],
      reminders: (results[13] as List<EventReminder>?) ?? const [],
    );
  }

  @override
  Stream<Event?> watchEventById(String id) async* {
    yield await getEventById(id);

    final controller = StreamController<void>.broadcast();
    final s1 = (_db.select(_db.events)..where((t) => t.id.equals(id))).watch().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });
    final s2 = (_db.select(_db.entries)..where((t) => t.eventId.equals(id))).watch().listen((_) {
      if (!controller.isClosed) controller.add(null);
    });

    try {
      await for (final _ in controller.stream) {
        yield await getEventById(id);
      }
    } finally {
      await s1.cancel();
      await s2.cancel();
      await controller.close();
    }
  }

  @override
  Future<void> createEvent(Event event) async {
    // 1. Insert main event row with all metadata
    await _db.eventsDao.insertExtendedEventRow(event);

    // 2. Insert any initial functions
    for (final fn in event.functions) {
      await _db.eventsDao.insertFunction(fn);
    }

    // 3. Insert participants
    for (final p in event.participants) {
      await _db.eventsDao.insertParticipant(p);
    }

    // 4. Insert guests
    for (final g in event.guests) {
      await _db.eventsDao.insertGuest(g);
    }

    // 5. Insert tasks
    for (final t in event.tasks) {
      await _db.eventsDao.insertTask(t);
    }

    // 6. Insert schedule items
    for (final s in event.schedule) {
      await _db.eventsDao.insertScheduleItem(s);
    }

    // 7. Insert budget categories
    for (final b in event.budgetCategories) {
      await _db.eventsDao.insertBudgetCategory(b);
    }

    // 8. Insert reminders
    for (final r in event.reminders) {
      await _db.eventsDao.insertReminder(r);
    }

    // 9. Log activity
    await _db.eventsDao.insertActivityLog(
      EventActivityLog(
        id: const Uuid().v4(),
        eventId: event.id,
        action: 'कार्यक्रम तैयार किया गया',
        details: 'नया कार्यक्रम "${event.title}" जोड़ा गया',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateEvent(Event event) async {
    await _db.eventsDao.insertExtendedEventRow(event);
    await _db.eventsDao.insertActivityLog(
      EventActivityLog(
        id: const Uuid().v4(),
        eventId: event.id,
        action: 'विवरण अद्यतन किया गया',
        details: 'कार्यक्रम की जानकारी सुरक्षित की गई',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> archiveEvent(String id) async {
    await _db.eventsDao.archiveEvent(id);
    await _db.eventsDao.insertActivityLog(
      EventActivityLog(
        id: const Uuid().v4(),
        eventId: id,
        action: 'कार्यक्रम संग्रहीत किया गया',
        details: 'इवेंट को आर्काइव में भेजा गया',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> restoreEvent(String id) async {
    await _db.eventsDao.restoreEvent(id);
    await _db.eventsDao.insertActivityLog(
      EventActivityLog(
        id: const Uuid().v4(),
        eventId: id,
        action: 'कार्यक्रम पुनर्स्थापित किया गया',
        details: 'इवेंट को आर्काइव से वापस लाया गया',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> cancelEvent(String id, String reason) async {
    await _db.eventsDao.cancelEvent(id, reason);
  }

  @override
  Future<String> duplicateEvent(String sourceEventId, String newTitle, String newDate) async {
    final source = await getEventById(sourceEventId);
    if (source == null) throw Exception('Source event not found');

    final newId = const Uuid().v4();
    final now = DateTime.now();

    final duplicated = Event(
      id: newId,
      title: newTitle,
      eventType: source.eventType,
      category: source.category,
      eventDate: newDate,
      endDate: source.endDate,
      startTime: source.startTime,
      endTime: source.endTime,
      isAllDay: source.isAllDay,
      venue: source.venue,
      address: source.address,
      villageCity: source.villageCity,
      landmark: source.landmark,
      mapLink: source.mapLink,
      description: source.description,
      notes: source.notes,
      status: EventStatus.planned,
      priority: source.priority,
      budgetEstimatedPaise: source.budgetEstimatedPaise,
      createdAt: now,
      updatedAt: now,
      functions: source.functions.map((fn) => EventFunction(
        id: const Uuid().v4(),
        eventId: newId,
        title: fn.title,
        functionDate: newDate,
        startTime: fn.startTime,
        endTime: fn.endTime,
        venue: fn.venue,
        description: fn.description,
        status: EventStatus.planned,
        createdAt: now,
        updatedAt: now,
      )).toList(),
      tasks: source.tasks.map((t) => EventTask(
        id: const Uuid().v4(),
        eventId: newId,
        title: t.title,
        description: t.description,
        assignedPersonName: t.assignedPersonName,
        dueDate: newDate,
        priority: t.priority,
        status: TaskStatus.pending,
        createdAt: now,
      )).toList(),
      budgetCategories: source.budgetCategories.map((b) => EventBudgetCategory(
        id: const Uuid().v4(),
        eventId: newId,
        categoryName: b.categoryName,
        estimatedAmountPaise: b.estimatedAmountPaise,
        actualAmountPaise: 0,
        notes: b.notes,
        createdAt: now,
      )).toList(),
    );

    await createEvent(duplicated);
    return newId;
  }

  @override
  Future<void> deleteEventSafely(String id) async {
    await _db.eventsDao.deleteEventSafely(id);
  }

  // =========================================================================
  // SUB-ENTITY CRUD OPERATIONS
  // =========================================================================

  @override
  Future<void> addFunction(EventFunction fn) async {
    await _db.eventsDao.insertFunction(fn);
    await _db.eventsDao.insertActivityLog(
      EventActivityLog(
        id: const Uuid().v4(),
        eventId: fn.eventId,
        action: 'रस्म / फंक्शन जोड़ा गया',
        details: fn.title,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateFunction(EventFunction fn) async {
    await _db.eventsDao.insertFunction(fn);
  }

  @override
  Future<void> deleteFunction(String id) async {
    await _db.eventsDao.deleteFunction(id);
  }

  @override
  Future<void> addTask(EventTask task) async {
    await _db.eventsDao.insertTask(task);
    await _db.eventsDao.insertActivityLog(
      EventActivityLog(
        id: const Uuid().v4(),
        eventId: task.eventId,
        action: 'कार्य जोड़ा गया',
        details: task.title,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateTask(EventTask task) async {
    await _db.eventsDao.insertTask(task);
  }

  @override
  Future<void> toggleTaskStatus(String id, TaskStatus status) async {
    await _db.eventsDao.toggleTaskStatus(id, status);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _db.eventsDao.deleteTask(id);
  }

  @override
  Future<void> addGuest(EventGuest guest) async {
    await _db.eventsDao.insertGuest(guest);
  }

  @override
  Future<void> updateGuest(EventGuest guest) async {
    await _db.eventsDao.insertGuest(guest);
  }

  @override
  Future<void> deleteGuest(String id) async {
    await _db.eventsDao.deleteGuest(id);
  }

  @override
  Future<void> addParticipant(EventParticipant participant) async {
    await _db.eventsDao.insertParticipant(participant);
  }

  @override
  Future<void> updateParticipant(EventParticipant participant) async {
    await _db.eventsDao.insertParticipant(participant);
  }

  @override
  Future<void> removeParticipant(String id) async {
    await _db.eventsDao.deleteParticipant(id);
  }

  @override
  Future<void> addBudgetCategory(EventBudgetCategory cat) async {
    await _db.eventsDao.insertBudgetCategory(cat);
  }

  @override
  Future<void> updateBudgetCategory(EventBudgetCategory cat) async {
    await _db.eventsDao.insertBudgetCategory(cat);
  }

  @override
  Future<void> deleteBudgetCategory(String id) async {
    await _db.eventsDao.deleteBudgetCategory(id);
  }

  @override
  Future<void> addNote(EventNote note) async {
    await _db.eventsDao.insertNote(note);
  }

  @override
  Future<void> updateNote(EventNote note) async {
    await _db.eventsDao.insertNote(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    await _db.eventsDao.deleteNote(id);
  }

  @override
  Future<void> addReminder(EventReminder reminder) async {
    await _db.eventsDao.insertReminder(reminder);
  }

  @override
  Future<void> toggleReminder(String id, bool isEnabled) async {
    await _db.eventsDao.toggleReminder(id, isEnabled);
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _db.eventsDao.deleteReminder(id);
  }

  // =========================================================================
  // CONFLICT DETECTION
  // =========================================================================

  @override
  Future<List<String>> detectConflicts(Event event) async {
    final conflicts = <String>[];
    final allEvents = await getAllActiveEvents();

    for (final other in allEvents) {
      if (other.id == event.id) continue;

      // 1. Same date conflict
      if (other.eventDate == event.eventDate) {
        if (event.startTime != null &&
            other.startTime != null &&
            event.startTime == other.startTime) {
          conflicts.add(
            'समय टकराव: "${other.title}" भी इसी समय (${event.startTime}) पर निर्धारित है।',
          );
        } else {
          conflicts.add(
            'तिथि टकराव: "${other.title}" भी इसी दिनांक (${event.eventDate}) को है।',
          );
        }
      }

      // 2. Similar title in same month
      if (other.title.trim().toLowerCase() == event.title.trim().toLowerCase()) {
        final otherMonth = other.eventDate.length >= 7 ? other.eventDate.substring(0, 7) : '';
        final thisMonth = event.eventDate.length >= 7 ? event.eventDate.substring(0, 7) : '';
        if (otherMonth == thisMonth) {
          conflicts.add(
            'संभावित डुप्लिकेट: समान नाम "${other.title}" का कार्यक्रम इसी महीने में पहले से मौजूद है।',
          );
        }
      }
    }

    // 3. Task due date after event date
    final eventFinalDate = event.endDate ?? event.eventDate;
    for (final task in event.tasks) {
      if (task.dueDate != null && task.dueDate!.isNotEmpty) {
        if (task.dueDate!.compareTo(eventFinalDate) > 0) {
          conflicts.add(
            'कार्य विलंब: कार्य "${task.title}" की अंतिम तिथि (${task.dueDate}) कार्यक्रम समाप्ति के बाद की है।',
          );
        }
      }
    }

    return conflicts;
  }

  Event _mapToEntity(
    EventRow r, {
    Map<String, dynamic>? extended,
    int? totalReceived,
    int? totalGiven,
    int? totalCount,
    List<EventFunction>? functions,
    List<EventParticipant>? participants,
    List<EventGuest>? guests,
    List<EventTask>? tasks,
    List<EventScheduleItem>? schedule,
    List<EventBudgetCategory>? budgetCategories,
    List<EventNote>? notes,
    List<EventAttachment>? attachments,
    List<EventActivityLog>? activityLogs,
    List<EventReminder>? reminders,
  }) {
    final ext = extended ?? const {};
    final category = ext['category']?.toString();
    final endDate = ext['end_date']?.toString();
    final startTime = ext['start_time']?.toString();
    final endTime = ext['end_time']?.toString();
    final isAllDay = ext['is_all_day'] == 1;
    final address = ext['address']?.toString();
    final villageCity = ext['village_city']?.toString();
    final landmark = ext['landmark']?.toString();
    final mapLink = ext['map_link']?.toString();
    final description = ext['description']?.toString();
    final statusStr = ext['status']?.toString();
    final priorityStr = ext['priority']?.toString();
    final budgetEstimated = (ext['budget_estimated_paise'] as num?)?.toInt();

    return Event(
      id: r.id,
      title: r.title,
      eventType: EventType.fromString(r.eventType),
      category: category?.isNotEmpty == true ? category : null,
      eventDate: r.eventDate,
      endDate: endDate?.isNotEmpty == true ? endDate : null,
      startTime: startTime?.isNotEmpty == true ? startTime : null,
      endTime: endTime?.isNotEmpty == true ? endTime : null,
      isAllDay: isAllDay,
      venue: r.venue,
      address: address?.isNotEmpty == true ? address : null,
      villageCity: villageCity?.isNotEmpty == true ? villageCity : null,
      landmark: landmark?.isNotEmpty == true ? landmark : null,
      mapLink: mapLink?.isNotEmpty == true ? mapLink : null,
      description: description?.isNotEmpty == true ? description : null,
      notes: r.notes,
      status: EventStatus.fromString(statusStr),
      priority: EventPriority.fromString(priorityStr),
      budgetEstimatedPaise: budgetEstimated != null && budgetEstimated > 0 ? budgetEstimated : null,
      createdAt: DateTime.tryParse(r.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r.updatedAt) ?? DateTime.now(),
      archivedAt: r.archivedAt != null && r.archivedAt!.isNotEmpty ? DateTime.tryParse(r.archivedAt!) : null,
      totalReceivedPaise: totalReceived,
      totalGivenPaise: totalGiven,
      totalEntriesCount: totalCount,
      functions: functions ?? const [],
      participants: participants ?? const [],
      guests: guests ?? const [],
      tasks: tasks ?? const [],
      schedule: schedule ?? const [],
      budgetCategories: budgetCategories ?? const [],
      notesList: notes ?? const [],
      attachments: attachments ?? const [],
      activityLogs: activityLogs ?? const [],
      reminders: reminders ?? const [],
    );
  }
}
