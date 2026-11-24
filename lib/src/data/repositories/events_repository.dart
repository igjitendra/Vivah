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

  @override
  Stream<List<Event>> watchActiveEvents() {
    return _db.eventsDao.watchActiveEvents().asyncMap((rows) async {
      final list = <Event>[];
      for (final r in rows) {
        final ext = await _db.eventsDao.getExtendedColumns(r.id);
        list.add(_mapToEntity(r, extended: ext));
      }
      return list;
    });
  }

  @override
  Stream<List<Event>> watchArchivedEvents() {
    return _db.eventsDao.watchArchivedEvents().asyncMap((rows) async {
      final list = <Event>[];
      for (final r in rows) {
        final ext = await _db.eventsDao.getExtendedColumns(r.id);
        list.add(_mapToEntity(r, extended: ext));
      }
      return list;
    });
  }

  @override
  Future<List<Event>> getUpcomingEvents() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db.eventsDao.getUpcomingEvents(today);
    final list = <Event>[];
    for (final r in rows) {
      final ext = await _db.eventsDao.getExtendedColumns(r.id);
      list.add(_mapToEntity(r, extended: ext));
    }
    return list;
  }

  @override
  Future<List<Event>> getPastEvents() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _db.eventsDao.getPastEvents(today);
    final list = <Event>[];
    for (final r in rows) {
      final ext = await _db.eventsDao.getExtendedColumns(r.id);
      list.add(_mapToEntity(r, extended: ext));
    }
    return list;
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final rows = await _db.eventsDao.searchEvents(query);
    final list = <Event>[];
    for (final r in rows) {
      final ext = await _db.eventsDao.getExtendedColumns(r.id);
      list.add(_mapToEntity(r, extended: ext));
    }
    return list;
  }

  @override
  Future<Event?> getEventById(String id) async {
    final row = await _db.eventsDao.getEventById(id);
    if (row == null) return null;

    final received = await _db.entriesDao.getEventReceivedTotal(id);
    final given = await _db.entriesDao.getEventGivenTotal(id);
    final count = await _db.eventsDao.countEntriesForEvent(id);
    final ext = await _db.eventsDao.getExtendedColumns(id);

    // Fetch all sub-entities
    final functions = await _db.eventsDao.getFunctionsForEvent(id);
    final participants = await _db.eventsDao.getParticipantsForEvent(id);
    final guests = await _db.eventsDao.getGuestsForEvent(id);
    final tasks = await _db.eventsDao.getTasksForEvent(id);
    final schedule = await _db.eventsDao.getScheduleForEvent(id);
    final budgetCategories = await _db.eventsDao.getBudgetCategoriesForEvent(id);
    final notes = await _db.eventsDao.getNotesForEvent(id);
    final attachments = await _db.eventsDao.getAttachmentsForEvent(id);
    final activityLogs = await _db.eventsDao.getActivityLogsForEvent(id);
    final reminders = await _db.eventsDao.getRemindersForEvent(id);

    return _mapToEntity(
      row,
      extended: ext,
      totalReceived: received,
      totalGiven: given,
      totalCount: count,
      functions: functions,
      participants: participants,
      guests: guests,
      tasks: tasks,
      schedule: schedule,
      budgetCategories: budgetCategories,
      notes: notes,
      attachments: attachments,
      activityLogs: activityLogs,
      reminders: reminders,
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
    Map<String, dynamic> extended = const {},
    int? totalReceived,
    int? totalGiven,
    int? totalCount,
    List<EventFunction> functions = const [],
    List<EventParticipant> participants = const [],
    List<EventGuest> guests = const [],
    List<EventTask> tasks = const [],
    List<EventScheduleItem> schedule = const [],
    List<EventBudgetCategory> budgetCategories = const [],
    List<EventNote> notes = const [],
    List<EventAttachment> attachments = const [],
    List<EventActivityLog> activityLogs = const [],
    List<EventReminder> reminders = const [],
  }) {
    final category = extended['category']?.toString();
    final endDate = extended['end_date']?.toString();
    final startTime = extended['start_time']?.toString();
    final endTime = extended['end_time']?.toString();
    final isAllDay = extended['is_all_day'] == 1;
    final address = extended['address']?.toString();
    final villageCity = extended['village_city']?.toString();
    final landmark = extended['landmark']?.toString();
    final mapLink = extended['map_link']?.toString();
    final description = extended['description']?.toString();
    final statusStr = extended['status']?.toString();
    final priorityStr = extended['priority']?.toString();
    final budgetEstimated = (extended['budget_estimated_paise'] as num?)?.toInt();

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
      functions: functions,
      participants: participants,
      guests: guests,
      tasks: tasks,
      schedule: schedule,
      budgetCategories: budgetCategories,
      notesList: notes,
      attachments: attachments,
      activityLogs: activityLogs,
      reminders: reminders,
    );
  }
}
