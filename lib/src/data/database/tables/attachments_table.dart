import 'package:drift/drift.dart';
import 'entries_table.dart';

/// Attachments table for entry proof images (शगुन का सबूत).
/// Each entry can have at most one proof image with an optional caption note.
@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().named('entry_id').references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get localPath => text().named('local_path')();
  TextColumn get note => text().nullable()(); // Caption like "चेक no. 1234"
  TextColumn get remotePath => text().named('remote_path').nullable()();
  TextColumn get createdAt =>
      text().named('created_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {id};
}
