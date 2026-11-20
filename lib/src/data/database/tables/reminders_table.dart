import 'package:drift/drift.dart';
import 'households_table.dart';
import 'people_table.dart';

/// Reminders table for upcoming event follow-ups and ceremonies.
/// Exactly mirrors SQLite table `reminders`.
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().named('household_id').references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get personId =>
      text().named('person_id').references(People, #id, onDelete: KeyAction.cascade)();
  TextColumn get eventTitle => text().named('event_title')();
  TextColumn get targetDate => text().named('target_date')();
  TextColumn get note => text().nullable()();
  BoolColumn get isCompleted =>
      boolean().named('is_completed').withDefault(const Constant(false))();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
