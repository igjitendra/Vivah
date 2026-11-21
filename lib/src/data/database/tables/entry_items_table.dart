import 'package:drift/drift.dart';
import 'entries_table.dart';

/// Entry items table representing physical non-cash gifts (चाँदी का सिक्का, कपड़े आदि).
/// Part 4 Specification: id, entry_id, item_name, quantity, unit,
/// estimated_value_paise, notes, created_at, updated_at.
@DataClassName('EntryItemRow')
class EntryItems extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().named('entry_id').references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemName => text().named('item_name')();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().nullable().withDefault(const Constant('संख्या'))();
  Int64Column get estimatedValuePaise =>
      int64().named('estimated_value_paise').nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
