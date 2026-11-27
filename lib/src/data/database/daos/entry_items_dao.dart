import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/entry_items_table.dart';

part 'entry_items_dao.g.dart';

/// DAO for EntryItems table (gifts and physical items)
@DriftAccessor(tables: [EntryItems])
class EntryItemsDao extends DatabaseAccessor<AppDatabase> with _$EntryItemsDaoMixin {
  EntryItemsDao(super.db);

  /// Get all items for an entry
  Future<List<EntryItemRow>> getItemsForEntry(String entryId) {
    return (select(entryItems)
          ..where((t) => t.entryId.equals(entryId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Watch items for an entry
  Stream<List<EntryItemRow>> watchItemsForEntry(String entryId) {
    return (select(entryItems)
          ..where((t) => t.entryId.equals(entryId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Insert a single item
  Future<int> insertItem(EntryItemsCompanion item) {
    return into(entryItems).insert(item);
  }

  /// Insert multiple items atomically
  Future<void> insertMultipleItems(List<EntryItemsCompanion> items) async {
    await batch((batch) {
      batch.insertAll(entryItems, items);
    });
  }

  /// Delete all items for an entry (used during entry update/replace)
  Future<int> deleteItemsForEntry(String entryId) {
    return (delete(entryItems)..where((t) => t.entryId.equals(entryId))).go();
  }

  /// Calculate total estimated value of physical gifts across all items
  Future<int> getTotalEstimatedGiftValuePaise() async {
    final sum = entryItems.estimatedValuePaise.sum();
    final row = await (selectOnly(entryItems)..addColumns([sum])).getSingleOrNull();
    return row?.read(sum)?.toInt() ?? 0;
  }

  /// Ensure photo_path column exists (self-healing guard)
  Future<void> _ensurePhotoColumn() async {
    try {
      await customStatement('ALTER TABLE entry_items ADD COLUMN photo_path TEXT;');
    } catch (_) {}
  }

  /// Save or clear photo_path for a gift item
  Future<void> updateItemPhotoPath(String itemId, String? photoPath) async {
    await _ensurePhotoColumn();
    await customUpdate(
      'UPDATE entry_items SET photo_path = ?, updated_at = ? WHERE id = ?',
      variables: [
        photoPath != null && photoPath.isNotEmpty
            ? Variable.withString(photoPath)
            : const Variable<String>(null),
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withString(itemId),
      ],
      updates: {entryItems},
    );
  }

  /// Fetch map of itemId -> photoPath for a single entry
  Future<Map<String, String>> getPhotoPathsForEntry(String entryId) async {
    return getPhotoPathsForEntries([entryId]);
  }

  /// Fetch map of itemId -> photoPath across multiple entry IDs safely
  Future<Map<String, String>> getPhotoPathsForEntries(List<String> entryIds) async {
    if (entryIds.isEmpty) return const {};
    await _ensurePhotoColumn();

    final Map<String, String> result = {};
    const chunkSize = 400;
    for (var i = 0; i < entryIds.length; i += chunkSize) {
      final chunk = entryIds.sublist(
        i,
        i + chunkSize > entryIds.length ? entryIds.length : i + chunkSize,
      );
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final rows = await customSelect(
        'SELECT id, photo_path FROM entry_items WHERE entry_id IN ($placeholders) AND photo_path IS NOT NULL AND photo_path != \'\'',
        variables: chunk.map((id) => Variable.withString(id)).toList(),
        readsFrom: {entryItems},
      ).get();
      for (final row in rows) {
        final id = row.readNullable<String>('id');
        final path = row.readNullable<String>('photo_path');
        if (id != null && path != null && path.isNotEmpty) {
          result[id] = path;
        }
      }
    }
    return result;
  }
}
