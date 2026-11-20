import 'package:drift/drift.dart';

/// Events table representing social and family ceremonies (शादी, मुंडन, गृह प्रवेश आदि).
/// Part 3C Specification: id, title, event_type, event_date, venue, notes, created_at, updated_at, archived_at.
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get eventType => text().named('event_type')();
  TextColumn get eventDate => text().named('event_date')(); // YYYY-MM-DD
  TextColumn get venue => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get archivedAt => text().named('archived_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
