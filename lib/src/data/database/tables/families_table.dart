import 'package:drift/drift.dart';

/// Families table representing clan or extended family units.
/// Part 3A Specification: id, name, description, notes, created_at, updated_at, archived_at.
class Families extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get archivedAt => text().named('archived_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
