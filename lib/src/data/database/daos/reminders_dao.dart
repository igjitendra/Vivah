import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/reminders_table.dart';

part 'reminders_dao.g.dart';

/// DAO for Reminders table
@DriftAccessor(tables: [Reminders])
class RemindersDao extends DatabaseAccessor<AppDatabase> with _$RemindersDaoMixin {
  RemindersDao(super.db);

  /// Get reminder by ID
  Future<ReminderRow?> getReminderById(String id) {
    return (select(reminders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get pending reminders on or before date
  Future<List<ReminderRow>> getPendingReminders(String beforeDateIso) {
    return (select(reminders)
          ..where((t) =>
              t.reminderDate.isSmallerOrEqualValue(beforeDateIso) & t.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.reminderDate)]))
        .get();
  }

  /// Watch all reminders
  Stream<List<ReminderRow>> watchAllReminders() {
    return (select(reminders)..orderBy([(t) => OrderingTerm.asc(t.reminderDate)])).watch();
  }

  /// Insert reminder
  Future<int> insertReminder(RemindersCompanion reminder) {
    return into(reminders).insert(reminder);
  }

  /// Mark reminder as completed
  Future<int> markCompleted(String id, bool completed) {
    return (update(reminders)..where((t) => t.id.equals(id))).write(
      RemindersCompanion(
        isCompleted: Value(completed),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Delete reminder
  Future<int> deleteReminder(String id) {
    return (delete(reminders)..where((t) => t.id.equals(id))).go();
  }
}
