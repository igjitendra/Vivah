import 'package:drift/drift.dart';
import 'entries_table.dart';

/// Reminders table for upcoming planned व्यवहार follow-ups.
/// Part 5 Specification: id, entry_id, reminder_date, title, notes,
/// is_completed, created_at, updated_at.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().named('entry_id').nullable().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get reminderDate => text().named('reminder_date')(); // YYYY-MM-DD
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().named('is_completed').withDefault(const Constant(false))();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
