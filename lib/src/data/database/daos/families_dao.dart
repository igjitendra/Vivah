import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/families_table.dart';
import '../tables/people_table.dart';

part 'families_dao.g.dart';

/// DAO for Families table
@DriftAccessor(tables: [Families, People])
class FamiliesDao extends DatabaseAccessor<AppDatabase> with _$FamiliesDaoMixin {
  FamiliesDao(super.db);

  /// Get family by unique ID
  Future<FamilyRow?> getFamilyById(String id) {
    return (select(families)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get all active (non-archived) families
  Future<List<FamilyRow>> getAllActiveFamilies() {
    return (select(families)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Watch all active families stream
  Stream<List<FamilyRow>> watchActiveFamilies() {
    return (select(families)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Search families by name
  Future<List<FamilyRow>> searchFamilies(String query) {
    final pattern = '%$query%';
    return (select(families)
          ..where((t) => t.name.like(pattern) & t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Insert new family
  Future<int> insertFamily(FamiliesCompanion entry) {
    return into(families).insert(entry);
  }

  /// Update existing family
  Future<bool> updateFamily(FamiliesCompanion entry) {
    return update(families).replace(entry);
  }

  /// Soft archive a family (never delete historical records)
  Future<int> archiveFamily(String id) {
    return (update(families)..where((t) => t.id.equals(id))).write(
      FamiliesCompanion(
        archivedAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Count number of people belonging to this family
  Future<int> countPeopleInFamily(String familyId) async {
    final count = people.id.count();
    final row = await (selectOnly(people)
          ..addColumns([count])
          ..where(people.familyId.equals(familyId) & people.archivedAt.isNull()))
        .getSingleOrNull();
    return row?.read(count) ?? 0;
  }
}
