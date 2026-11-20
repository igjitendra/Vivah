import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/people_table.dart';
import '../tables/entries_table.dart';

part 'people_dao.g.dart';

/// DAO for People table
@DriftAccessor(tables: [People, Entries])
class PeopleDao extends DatabaseAccessor<AppDatabase> with _$PeopleDaoMixin {
  PeopleDao(super.db);

  /// Get person by ID
  Future<PersonRow?> getPersonById(String id) {
    return (select(people)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get all active (non-archived) people
  Future<List<PersonRow>> getAllActivePeople() {
    return (select(people)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  /// Watch all active people
  Stream<List<PersonRow>> watchActivePeople() {
    return (select(people)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch();
  }

  /// Search people by full name or phone number
  Future<List<PersonRow>> searchPeople(String query) {
    final pattern = '%$query%';
    return (select(people)
          ..where((t) =>
              (t.fullName.like(pattern) | t.phoneNumber.like(pattern) | t.address.like(pattern)) &
              t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  /// Get people belonging to a family
  Future<List<PersonRow>> getPeopleByFamily(String familyId) {
    return (select(people)
          ..where((t) => t.familyId.equals(familyId) & t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  /// Insert new person
  Future<int> insertPerson(PeopleCompanion person) {
    return into(people).insert(person);
  }

  /// Update person
  Future<bool> updatePerson(PeopleCompanion person) {
    return update(people).replace(person);
  }

  /// Soft archive a person
  Future<int> archivePerson(String id) {
    return (update(people)..where((t) => t.id.equals(id))).write(
      PeopleCompanion(
        archivedAt: Value(DateTime.now().toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  /// Count transactions associated with this person (used to enforce deletion protection)
  Future<int> countEntriesForPerson(String personId) async {
    final count = entries.id.count();
    final row = await (selectOnly(entries)
          ..addColumns([count])
          ..where(entries.personId.equals(personId) & entries.archivedAt.isNull()))
        .getSingleOrNull();
    return row?.read(count) ?? 0;
  }
}
