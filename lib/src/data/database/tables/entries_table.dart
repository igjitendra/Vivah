import 'package:drift/drift.dart';
import 'people_table.dart';
import 'events_table.dart';

/// Entries table representing core व्यवहार (Transactions).
/// Part 3D Specification: id, person_id, event_id, direction, transaction_type,
/// status, amount_paise, transaction_date, notes, created_at, updated_at,
/// recorded_at, cancelled_at, archived_at.
@DataClassName('EntryRow')
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get personId =>
      text().named('person_id').references(People, #id, onDelete: KeyAction.restrict)();
  TextColumn get eventId =>
      text().named('event_id').nullable().references(Events, #id, onDelete: KeyAction.setNull)();
  TextColumn get direction =>
      text().customConstraint("NOT NULL CHECK (direction IN ('given', 'received', 'diya', 'mila'))")();
  TextColumn get transactionType =>
      text().named('transaction_type').withDefault(const Constant('cash')).customConstraint(
          "NOT NULL DEFAULT 'cash' CHECK (transaction_type IN ('cash', 'item', 'cash_and_item'))")();
  TextColumn get status =>
      text().customConstraint("NOT NULL DEFAULT 'recorded' CHECK (status IN ('planned', 'recorded', 'cancelled'))")();
  Int64Column get amountPaise =>
      int64().named('amount_paise').nullable()();
  TextColumn get transactionDate => text().named('transaction_date')(); // YYYY-MM-DD
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get recordedAt => text().named('recorded_at').nullable()();
  TextColumn get cancelledAt => text().named('cancelled_at').nullable()();
  TextColumn get archivedAt => text().named('archived_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
