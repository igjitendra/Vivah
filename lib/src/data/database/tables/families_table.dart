import 'package:drift/drift.dart';
import 'households_table.dart';

/// Families table representing clan or extended family units.
/// Exactly mirrors SQLite table `families`.
class Families extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().named('household_id').references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get village => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
