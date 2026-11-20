import 'package:drift/drift.dart';

/// Households table representing the user's family ledger.
/// Exactly mirrors SQLite table `households`.
class Households extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
