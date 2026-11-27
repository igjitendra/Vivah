import 'package:drift/drift.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../app_database.dart';
import '../tables/events_table.dart';
import '../tables/entries_table.dart';

part 'events_dao.g.dart';

/// DAO for Events and all associated advanced event sub-systems.
/// 100% offline, transactional, and foreign-key safe.
@DriftAccessor(tables: [Events, Entries])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  /// Get basic event row by ID
  Future<EventRow?> getEventById(String id) {
    return (select(events)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get all active events
  Future<List<EventRow>> getAllActiveEvents() {
    return (select(events)
          ..where((t) => t.archivedAt.isNull() | t.archivedAt.equals(''))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  /// Watch all active events
  Stream<List<EventRow>> watchActiveEvents() {
    return (select(events)
          ..where((t) => t.archivedAt.isNull() | t.archivedAt.equals(''))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .watch();
  }

  /// Watch all archived events
  Stream<List<EventRow>> watchArchivedEvents() {
    return (select(events)
          ..where((t) => t.archivedAt.isNotNull() & t.archivedAt.isNotValue(''))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .watch();
  }

  /// Get upcoming events (event_date >= today)
  Future<List<EventRow>> getUpcomingEvents(String todayIso) {
    return (select(events)
          ..where((t) =>
              t.eventDate.isBiggerOrEqualValue(todayIso) &
              (t.archivedAt.isNull() | t.archivedAt.equals('')))
          ..orderBy([(t) => OrderingTerm.asc(t.eventDate)]))
        .get();
  }

  /// Get past events (event_date < today)
  Future<List<EventRow>> getPastEvents(String todayIso) {
    return (select(events)
          ..where((t) =>
              t.eventDate.isSmallerThanValue(todayIso) &
              (t.archivedAt.isNull() | t.archivedAt.equals('')))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
  }

  /// Search events by title, venue, or event_type
  Future<List<EventRow>> searchEvents(String query) {
    final pattern = '%$query%';
    return (select(events)
          ..where((t) =>
              (t.title.like(pattern) | t.venue.like(pattern) | t.eventType.like(pattern)) &
              (t.archivedAt.isNull() | t.archivedAt.equals('')))
          ..orderBy([(t) => OrderingTerm.desc(t.eventDate)]))
        .get();
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

  /// Basic insert event
  Future<int> insertEvent(EventsCompanion event) {
    return into(events).insert(event);
  }

  /// Basic update event
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

  /// Restore an archived event
  Future<int> restoreEvent(String id) {
    return (update(events)..where((t) => t.id.equals(id))).write(
      EventsCompanion(
        archivedAt: const Value(null),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Cancel an event safely with a reason logged in activity log
  Future<void> cancelEvent(String id, String reason) async {
    await customUpdate(
      "UPDATE events SET status = 'cancelled', updated_at = ? WHERE id = ?",
      variables: [
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString(id),
      ],
      updates: {events},
    );
    await insertActivityLog(
      EventActivityLog(
        id: '${id}_cancel_${DateTime.now().millisecondsSinceEpoch}',
        eventId: id,
        action: 'कार्यक्रम रद्द किया गया',
        details: reason.isNotEmpty ? reason : 'कोई कारण नहीं दिया गया',
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Safe Delete: Nullifies event_id in entries so transactions are NEVER lost!
  Future<void> deleteEventSafely(String id) async {
    await transaction(() async {
      // 1. Preserve financial transactions by unlinking them safely
      await customUpdate(
        'UPDATE entries SET event_id = NULL WHERE event_id = ?',
        variables: [Variable.withString(id)],
        updates: {entries},
      );

      // 2. Delete event row (CASCADE removes functions, tasks, guests, budget, notes)
      await (delete(events)..where((t) => t.id.equals(id))).go();
    });
  }

  // =========================================================================
  // ADVANCED EXTENDED EVENT PERSISTENCE
  // =========================================================================

  Variable<String> _nullableString(String? val) {
    if (val == null || val.trim().isEmpty) {
      return const Variable<String>(null);
    }
    return Variable.withString(val.trim());
  }

  /// Inserts or updates an extended event with full metadata without triggering FK cascade deletes
  Future<void> insertExtendedEventRow(Event event) async {
    await customInsert(
      '''
      INSERT INTO events (
        id, title, event_type, category, event_date, end_date, start_time, end_time,
        is_all_day, venue, address, village_city, landmark, map_link, description,
        notes, status, priority, budget_estimated_paise,
        event_scope, host_person_id, host_person_name, attending_family_note,
        created_at, updated_at, archived_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        event_type = excluded.event_type,
        category = excluded.category,
        event_date = excluded.event_date,
        end_date = excluded.end_date,
        start_time = excluded.start_time,
        end_time = excluded.end_time,
        is_all_day = excluded.is_all_day,
        venue = excluded.venue,
        address = excluded.address,
        village_city = excluded.village_city,
        landmark = excluded.landmark,
        map_link = excluded.map_link,
        description = excluded.description,
        notes = excluded.notes,
        status = excluded.status,
        priority = excluded.priority,
        budget_estimated_paise = excluded.budget_estimated_paise,
        event_scope = excluded.event_scope,
        host_person_id = excluded.host_person_id,
        host_person_name = excluded.host_person_name,
        attending_family_note = excluded.attending_family_note,
        updated_at = excluded.updated_at,
        archived_at = excluded.archived_at
      ''',
      variables: [
        Variable.withString(event.id),
        Variable.withString(event.title.trim()),
        Variable.withString(event.eventType.labelHindi),
        _nullableString(event.category),
        Variable.withString(event.eventDate),
        _nullableString(event.endDate),
        _nullableString(event.startTime),
        _nullableString(event.endTime),
        Variable.withInt(event.isAllDay ? 1 : 0),
        _nullableString(event.venue),
        _nullableString(event.address),
        _nullableString(event.villageCity),
        _nullableString(event.landmark),
        _nullableString(event.mapLink),
        _nullableString(event.description),
        _nullableString(event.notes),
        Variable.withString(event.status.name),
        Variable.withString(event.priority.name),
        event.budgetEstimatedPaise != null && event.budgetEstimatedPaise! > 0
            ? Variable.withInt(event.budgetEstimatedPaise!)
            : const Variable<int>(null),
        Variable.withString(event.eventScope.value),
        _nullableString(event.hostPersonId),
        _nullableString(event.hostPersonName),
        _nullableString(event.attendingFamilyNote),
        Variable.withString(event.createdAt.toIso8601String()),
        Variable.withString(event.updatedAt.toIso8601String()),
        _nullableString(event.archivedAt?.toIso8601String()),
      ],
      updates: {events},
    );
  }

  /// Get extra extended columns for an event from SQLite
  Future<Map<String, dynamic>> getExtendedColumns(String id) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM events WHERE id = ?',
        variables: [Variable.withString(id)],
        readsFrom: {events},
      ).get();
      if (rows.isNotEmpty) {
        return rows.first.data;
      }
    } catch (_) {}
    return {};
  }

  // =========================================================================
  // SUB-ENTITIES CRUD
  // =========================================================================

  // 1. Functions
  EventFunction _mapFunctionRow(Map<String, dynamic> d) {
    return EventFunction(
      id: d['id'] as String,
      eventId: d['event_id'] as String,
      title: d['title'] as String,
      functionDate: d['function_date'] as String,
      startTime: d['start_time'] as String?,
      endTime: d['end_time'] as String?,
      venue: d['venue'] as String?,
      description: d['description'] as String?,
      status: EventStatus.fromString(d['status'] as String?),
      createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(d['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<List<EventFunction>> getFunctionsForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_functions WHERE event_id = ? ORDER BY function_date ASC, start_time ASC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) => _mapFunctionRow(r.data)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Batch loads all sub-functions grouped by event ID for list & calendar hydration.
  Future<Map<String, List<EventFunction>>> getAllFunctionsGroupedByEvent() async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_functions ORDER BY function_date ASC, start_time ASC',
      ).get();
      final grouped = <String, List<EventFunction>>{};
      for (final r in rows) {
        final fn = _mapFunctionRow(r.data);
        (grouped[fn.eventId] ??= []).add(fn);
      }
      return grouped;
    } catch (_) {
      return {};
    }
  }

  Future<void> insertFunction(EventFunction fn) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_functions (
        id, event_id, title, function_date, start_time, end_time, venue, description, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(fn.id),
        Variable.withString(fn.eventId),
        Variable.withString(fn.title),
        Variable.withString(fn.functionDate),
        _nullableString(fn.startTime),
        _nullableString(fn.endTime),
        _nullableString(fn.venue),
        _nullableString(fn.description),
        Variable.withString(fn.status.name),
        Variable.withString(fn.createdAt.toIso8601String()),
        Variable.withString(fn.updatedAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> deleteFunction(String id) async {
    await customUpdate(
      'DELETE FROM event_functions WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 2. Participants & Roles
  Future<List<EventParticipant>> getParticipantsForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_participants WHERE event_id = ? ORDER BY name ASC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventParticipant(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          personId: d['person_id'] as String?,
          familyId: d['family_id'] as String?,
          name: d['name'] as String,
          role: ParticipantRole.fromString(d['role'] as String?),
          phone: d['phone'] as String?,
          notes: d['notes'] as String?,
          createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertParticipant(EventParticipant p) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_participants (
        id, event_id, person_id, family_id, name, role, phone, notes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(p.id),
        Variable.withString(p.eventId),
        _nullableString(p.personId),
        _nullableString(p.familyId),
        Variable.withString(p.name),
        Variable.withString(p.role.name),
        _nullableString(p.phone),
        _nullableString(p.notes),
        Variable.withString(p.createdAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> deleteParticipant(String id) async {
    await customUpdate(
      'DELETE FROM event_participants WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 3. Guests & RSVP
  Future<List<EventGuest>> getGuestsForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_guests WHERE event_id = ? ORDER BY name ASC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventGuest(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          personId: d['person_id'] as String?,
          name: d['name'] as String,
          familyOrGroup: d['family_or_group'] as String?,
          phoneNumber: d['phone_number'] as String?,
          invitationStatus: InvitationStatus.fromString(d['invitation_status'] as String?),
          attendanceStatus: AttendanceStatus.fromString(d['attendance_status'] as String?),
          accompanyingCount: (d['accompanying_count'] as num?)?.toInt() ?? 0,
          notes: d['notes'] as String?,
          invitationDate: d['invitation_date'] as String?,
          createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertGuest(EventGuest g) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_guests (
        id, event_id, person_id, name, family_or_group, phone_number,
        invitation_status, attendance_status, accompanying_count, notes, invitation_date, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(g.id),
        Variable.withString(g.eventId),
        _nullableString(g.personId),
        Variable.withString(g.name),
        _nullableString(g.familyOrGroup),
        _nullableString(g.phoneNumber),
        Variable.withString(g.invitationStatus.name),
        Variable.withString(g.attendanceStatus.name),
        Variable.withInt(g.accompanyingCount),
        _nullableString(g.notes),
        _nullableString(g.invitationDate),
        Variable.withString(g.createdAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> deleteGuest(String id) async {
    await customUpdate(
      'DELETE FROM event_guests WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 4. Tasks & Checklist
  EventTask _mapTaskRow(Map<String, dynamic> d) {
    return EventTask(
      id: d['id'] as String,
      eventId: d['event_id'] as String,
      title: d['title'] as String,
      description: d['description'] as String?,
      assignedPersonName: d['assigned_person_name'] as String?,
      dueDate: d['due_date'] as String?,
      priority: EventPriority.fromString(d['priority'] as String?),
      status: TaskStatus.fromString(d['status'] as String?),
      completedAt: d['completed_at'] != null ? DateTime.tryParse(d['completed_at'].toString()) : null,
      createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<List<EventTask>> getTasksForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_tasks WHERE event_id = ? ORDER BY status ASC, due_date ASC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) => _mapTaskRow(r.data)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Batch loads all checklist tasks grouped by event ID for list progress badges.
  Future<Map<String, List<EventTask>>> getAllTasksGroupedByEvent() async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_tasks ORDER BY status ASC, due_date ASC',
      ).get();
      final grouped = <String, List<EventTask>>{};
      for (final r in rows) {
        final task = _mapTaskRow(r.data);
        (grouped[task.eventId] ??= []).add(task);
      }
      return grouped;
    } catch (_) {
      return {};
    }
  }

  Future<void> insertTask(EventTask t) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_tasks (
        id, event_id, title, description, assigned_person_name, due_date, priority, status, completed_at, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(t.id),
        Variable.withString(t.eventId),
        Variable.withString(t.title),
        _nullableString(t.description),
        _nullableString(t.assignedPersonName),
        _nullableString(t.dueDate),
        Variable.withString(t.priority.name),
        Variable.withString(t.status.name),
        _nullableString(t.completedAt?.toIso8601String()),
        Variable.withString(t.createdAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> toggleTaskStatus(String id, TaskStatus newStatus) async {
    final completedAt = newStatus == TaskStatus.completed ? DateTime.now().toIso8601String() : null;
    await customUpdate(
      'UPDATE event_tasks SET status = ?, completed_at = ? WHERE id = ?',
      variables: [
        Variable.withString(newStatus.name),
        _nullableString(completedAt),
        Variable.withString(id),
      ],
      updates: {events},
    );
  }

  Future<void> deleteTask(String id) async {
    await customUpdate(
      'DELETE FROM event_tasks WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 5. Schedule
  Future<List<EventScheduleItem>> getScheduleForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_schedule_items WHERE event_id = ? ORDER BY activity_date ASC, start_time ASC, sort_order ASC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventScheduleItem(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          functionId: d['function_id'] as String?,
          title: d['title'] as String,
          activityDate: d['activity_date'] as String,
          startTime: d['start_time'] as String,
          durationMinutes: (d['duration_minutes'] as num?)?.toInt() ?? 60,
          venue: d['venue'] as String?,
          responsiblePerson: d['responsible_person'] as String?,
          description: d['description'] as String?,
          status: d['status'] as String? ?? 'scheduled',
          sortOrder: (d['sort_order'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertScheduleItem(EventScheduleItem s) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_schedule_items (
        id, event_id, function_id, title, activity_date, start_time, duration_minutes,
        venue, responsible_person, description, status, sort_order
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(s.id),
        Variable.withString(s.eventId),
        _nullableString(s.functionId),
        Variable.withString(s.title),
        Variable.withString(s.activityDate),
        Variable.withString(s.startTime),
        Variable.withInt(s.durationMinutes),
        _nullableString(s.venue),
        _nullableString(s.responsiblePerson),
        _nullableString(s.description),
        Variable.withString(s.status),
        Variable.withInt(s.sortOrder),
      ],
      updates: {events},
    );
  }

  Future<void> deleteScheduleItem(String id) async {
    await customUpdate(
      'DELETE FROM event_schedule_items WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 6. Budget Categories
  Future<List<EventBudgetCategory>> getBudgetCategoriesForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_budget_categories WHERE event_id = ? ORDER BY category_name ASC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventBudgetCategory(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          categoryName: d['category_name'] as String,
          estimatedAmountPaise: (d['estimated_amount_paise'] as num?)?.toInt() ?? 0,
          actualAmountPaise: (d['actual_amount_paise'] as num?)?.toInt() ?? 0,
          notes: d['notes'] as String?,
          createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertBudgetCategory(EventBudgetCategory b) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_budget_categories (
        id, event_id, category_name, estimated_amount_paise, actual_amount_paise, notes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(b.id),
        Variable.withString(b.eventId),
        Variable.withString(b.categoryName),
        Variable.withInt(b.estimatedAmountPaise),
        Variable.withInt(b.actualAmountPaise),
        _nullableString(b.notes),
        Variable.withString(b.createdAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> deleteBudgetCategory(String id) async {
    await customUpdate(
      'DELETE FROM event_budget_categories WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 7. Notes
  Future<List<EventNote>> getNotesForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_notes WHERE event_id = ? ORDER BY created_at DESC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventNote(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          title: d['title'] as String,
          content: d['content'] as String,
          createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(d['updated_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertNote(EventNote n) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_notes (
        id, event_id, title, content, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(n.id),
        Variable.withString(n.eventId),
        Variable.withString(n.title),
        Variable.withString(n.content),
        Variable.withString(n.createdAt.toIso8601String()),
        Variable.withString(n.updatedAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> deleteNote(String id) async {
    await customUpdate(
      'DELETE FROM event_notes WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 8. Attachments
  Future<List<EventAttachment>> getAttachmentsForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_attachments WHERE event_id = ? ORDER BY created_at DESC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventAttachment(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          fileName: d['file_name'] as String,
          filePath: d['file_path'] as String,
          fileType: d['file_type'] as String?,
          fileSizeBytes: (d['file_size_bytes'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertAttachment(EventAttachment a) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_attachments (
        id, event_id, file_name, file_path, file_type, file_size_bytes, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(a.id),
        Variable.withString(a.eventId),
        Variable.withString(a.fileName),
        Variable.withString(a.filePath),
        _nullableString(a.fileType),
        Variable.withInt(a.fileSizeBytes),
        Variable.withString(a.createdAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> deleteAttachment(String id) async {
    await customUpdate(
      'DELETE FROM event_attachments WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }

  // 9. Activity Logs
  Future<List<EventActivityLog>> getActivityLogsForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_activity_logs WHERE event_id = ? ORDER BY timestamp DESC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventActivityLog(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          action: d['action'] as String,
          details: d['details'] as String?,
          timestamp: DateTime.tryParse(d['timestamp']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertActivityLog(EventActivityLog log) async {
    try {
      await customInsert(
        '''
        INSERT INTO event_activity_logs (
          id, event_id, action, details, timestamp
        ) VALUES (?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(log.id),
          Variable.withString(log.eventId),
          Variable.withString(log.action),
          Variable.withString(log.details ?? ''),
          Variable.withString(log.timestamp.toIso8601String()),
        ],
        updates: {events},
      );
    } catch (_) {}
  }

  // 10. Reminders
  Future<List<EventReminder>> getRemindersForEvent(String eventId) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM event_reminders WHERE event_id = ? ORDER BY reminder_date ASC',
        variables: [Variable.withString(eventId)],
      ).get();
      return rows.map((r) {
        final d = r.data;
        return EventReminder(
          id: d['id'] as String,
          eventId: d['event_id'] as String,
          title: d['title'] as String,
          reminderDate: d['reminder_date'] as String,
          reminderTime: d['reminder_time'] as String?,
          preset: d['preset'] as String?,
          isEnabled: (d['is_enabled'] as num?)?.toInt() == 1,
          isCompleted: (d['is_completed'] as num?)?.toInt() == 1,
          createdAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertReminder(EventReminder rem) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO event_reminders (
        id, event_id, title, reminder_date, reminder_time, preset, is_enabled, is_completed, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(rem.id),
        Variable.withString(rem.eventId),
        Variable.withString(rem.title),
        Variable.withString(rem.reminderDate),
        _nullableString(rem.reminderTime),
        _nullableString(rem.preset),
        Variable.withInt(rem.isEnabled ? 1 : 0),
        Variable.withInt(rem.isCompleted ? 1 : 0),
        Variable.withString(rem.createdAt.toIso8601String()),
      ],
      updates: {events},
    );
  }

  Future<void> toggleReminder(String id, bool isEnabled) async {
    await customUpdate(
      'UPDATE event_reminders SET is_enabled = ? WHERE id = ?',
      variables: [
        Variable.withInt(isEnabled ? 1 : 0),
        Variable.withString(id),
      ],
      updates: {events},
    );
  }

  Future<void> deleteReminder(String id) async {
    await customUpdate(
      'DELETE FROM event_reminders WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {events},
    );
  }
}
