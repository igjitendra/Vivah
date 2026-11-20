import 'package:drift/drift.dart';
import 'families_table.dart';

/// People table representing individuals involved in व्यवहार.
/// Part 3B Specification: id, family_id, full_name, phone_number,
/// relationship_label, address, notes, created_at, updated_at, archived_at.
class People extends Table {
  TextColumn get id => text()();
  TextColumn get familyId =>
      text().named('family_id').nullable().references(Families, #id, onDelete: KeyAction.setNull)();
  TextColumn get fullName => text().named('full_name')();
  TextColumn get phoneNumber => text().named('phone_number').nullable()();
  TextColumn get relationshipLabel => text().named('relationship_label').nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get archivedAt => text().named('archived_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
