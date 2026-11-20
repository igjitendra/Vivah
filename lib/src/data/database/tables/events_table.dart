import 'package:drift/drift.dart';
import 'households_table.dart';
import 'people_table.dart';

/// Events table representing ceremonies, occasions, and family functions.
/// Exactly mirrors SQLite table `events`.
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().named('household_id').references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get eventType => text().named('event_type')();
  TextColumn get eventDate => text().named('event_date')();
  TextColumn get personId =>
      text().named('person_id').nullable().references(People, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
