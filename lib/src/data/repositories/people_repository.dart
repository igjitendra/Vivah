import 'package:drift/drift.dart';
import '../../domain/entities/entities.dart';
import '../database/app_database.dart';

abstract class PeopleRepository {
  Future<List<Person>> getAllActivePeople();
  Stream<List<Person>> watchActivePeople();
  Future<List<Person>> searchPeople(String query);
  Future<Person?> getPersonById(String id);
  Future<void> createPerson(Person person);
  Future<void> updatePerson(Person person);
  Future<bool> canDeletePerson(String id);
  Future<void> archivePerson(String id);
}

class DriftPeopleRepository implements PeopleRepository {
  final AppDatabase _db;

  DriftPeopleRepository(this._db);

  @override
  Future<List<Person>> getAllActivePeople() async {
    final rows = await _db.peopleDao.getAllActivePeople();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<Person>> watchActivePeople() {
    return _db.peopleDao.watchActivePeople().map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<List<Person>> searchPeople(String query) async {
    final rows = await _db.peopleDao.searchPeople(query);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<Person?> getPersonById(String id) async {
    final row = await _db.peopleDao.getPersonById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> createPerson(Person person) async {
    await _db.peopleDao.insertPerson(
      PeopleCompanion.insert(
        id: person.id,
        fullName: person.fullName,
        familyId: Value(person.familyId),
        phoneNumber: Value(person.phoneNumber),
        relationshipLabel: Value(person.relationshipLabel),
        address: Value(person.address),
        notes: Value(person.notes),
        createdAt: Value(person.createdAt.toIso8601String()),
        updatedAt: Value(person.updatedAt.toIso8601String()),
      ),
    );
  }

  @override
  Future<void> updatePerson(Person person) async {
    await _db.peopleDao.updatePerson(
      PeopleCompanion.insert(
        id: person.id,
        fullName: person.fullName,
        familyId: Value(person.familyId),
        phoneNumber: Value(person.phoneNumber),
        relationshipLabel: Value(person.relationshipLabel),
        address: Value(person.address),
        notes: Value(person.notes),
        createdAt: Value(person.createdAt.toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Future<bool> canDeletePerson(String id) async {
    final entriesCount = await _db.peopleDao.countEntriesForPerson(id);
    return entriesCount == 0;
  }

  @override
  Future<void> archivePerson(String id) async {
    await _db.peopleDao.archivePerson(id);
  }

  Person _mapToEntity(PersonRow r) {
    return Person(
      id: r.id,
      familyId: r.familyId,
      fullName: r.fullName,
      phoneNumber: r.phoneNumber,
      relationshipLabel: r.relationshipLabel,
      address: r.address,
      notes: r.notes,
      createdAt: DateTime.tryParse(r.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r.updatedAt) ?? DateTime.now(),
      archivedAt: r.archivedAt != null ? DateTime.tryParse(r.archivedAt!) : null,
    );
  }
}
