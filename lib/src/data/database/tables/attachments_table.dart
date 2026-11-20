import 'package:drift/drift.dart';
import 'entries_table.dart';

/// Attachments table for optional receipt images or document vouchers.
/// Exactly mirrors SQLite table `attachments`.
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().named('entry_id').references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get localPath => text().named('local_path')();
  TextColumn get remotePath => text().named('remote_path').nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
