import 'package:drift/drift.dart';
import 'households_table.dart';
import 'events_table.dart';
import 'people_table.dart';

/// Entries table representing monetary ledger transactions (व्यवहार).
/// Exactly mirrors SQLite table `entries`.
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get householdId =>
      text().named('household_id').references(Households, #id, onDelete: KeyAction.cascade)();
  TextColumn get eventId =>
      text().named('event_id').references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get personId =>
      text().named('person_id').references(People, #id, onDelete: KeyAction.restrict)();
  TextColumn get direction =>
      text().customConstraint("NOT NULL CHECK (direction IN ('mila', 'diya'))")();
  Int64Column get cashAmountPaise =>
      int64().named('cash_amount_paise').withDefault(const Constant(0))();
  TextColumn get status =>
      text().customConstraint("NOT NULL DEFAULT 'recorded' CHECK (status IN ('planned', 'recorded', 'cancelled'))")();
  TextColumn get expectedDate => text().named('expected_date').nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get deletedAt => text().named('deleted_at').nullable()();
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {id};
}
