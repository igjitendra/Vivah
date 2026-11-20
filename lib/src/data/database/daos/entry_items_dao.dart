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
}
