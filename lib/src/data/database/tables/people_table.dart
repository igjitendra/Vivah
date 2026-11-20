import 'package:drift/drift.dart';
import 'households_table.dart';
import 'families_table.dart';

/// People table representing contacts and transaction counterparties.
/// Exactly mirrors SQLite table `people`.
class People extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().named('household_id').references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get familyId =>
      text().named('family_id').nullable().references(Families, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  TextColumn get village => text().nullable()();
  TextColumn get relationship => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
