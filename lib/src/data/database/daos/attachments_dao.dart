import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/attachments_table.dart';
import '../tables/entries_table.dart';

part 'attachments_dao.g.dart';

/// DAO for entry proof attachments (शगुन के सबूत की फ़ोटो).
@DriftAccessor(tables: [Attachments, Entries])
class AttachmentsDao extends DatabaseAccessor<AppDatabase> with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  /// Get the proof attachment for a specific entry (at most one).
  Future<AttachmentRow?> getProofForEntry(String entryId) {
    return (select(attachments)
          ..where((t) => t.entryId.equals(entryId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Watch the proof attachment for a specific entry reactively.
  Stream<AttachmentRow?> watchProofForEntry(String entryId) {
    return (select(attachments)
          ..where((t) => t.entryId.equals(entryId))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Insert or replace proof image for an entry.
  Future<void> setProof({
    required String id,
    required String entryId,
    required String localPath,
    String? note,
  }) async {
    // Delete existing proof for this entry first (one-per-entry constraint)
    await deleteProofForEntry(entryId);
    // Insert new
    await into(attachments).insert(AttachmentsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      localPath: Value(localPath),
      note: Value(note),
      createdAt: Value(DateTime.now().toIso8601String()),
    ));
  }

  /// Delete proof attachment for an entry.
  Future<int> deleteProofForEntry(String entryId) {
    return (delete(attachments)..where((t) => t.entryId.equals(entryId))).go();
  }
}
