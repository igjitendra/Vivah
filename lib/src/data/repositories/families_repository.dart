import 'package:drift/drift.dart';
import '../../domain/entities/entities.dart';
import '../database/app_database.dart';

abstract class FamiliesRepository {
  Future<List<Family>> getAllActiveFamilies();
  Stream<List<Family>> watchActiveFamilies();
  Future<List<Family>> searchFamilies(String query);
  Future<Family?> getFamilyById(String id);
  Future<void> createFamily(Family family);
  Future<void> updateFamily(Family family);
  Future<void> archiveFamily(String id);
  Future<int> countPeopleInFamily(String familyId);
}

class DriftFamiliesRepository implements FamiliesRepository {
  final AppDatabase _db;

  DriftFamiliesRepository(this._db);

  @override
  Future<List<Family>> getAllActiveFamilies() async {
    final rows = await _db.familiesDao.getAllActiveFamilies();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<Family>> watchActiveFamilies() {
    return _db.familiesDao.watchActiveFamilies().map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<List<Family>> searchFamilies(String query) async {
    final rows = await _db.familiesDao.searchFamilies(query);
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<Family?> getFamilyById(String id) async {
    final row = await _db.familiesDao.getFamilyById(id);
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> createFamily(Family family) async {
    await _db.familiesDao.insertFamily(
      FamiliesCompanion.insert(
        id: family.id,
        name: family.name,
        description: Value(family.description),
        notes: Value(family.notes),
        createdAt: Value(family.createdAt.toIso8601String()),
        updatedAt: Value(family.updatedAt.toIso8601String()),
      ),
    );
  }

  @override
  Future<void> updateFamily(Family family) async {
    await _db.familiesDao.updateFamily(
      FamiliesCompanion.insert(
        id: family.id,
        name: family.name,
        description: Value(family.description),
        notes: Value(family.notes),
        createdAt: Value(family.createdAt.toIso8601String()),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Future<void> archiveFamily(String id) async {
    await _db.familiesDao.archiveFamily(id);
  }

  @override
  Future<int> countPeopleInFamily(String familyId) {
    return _db.familiesDao.countPeopleInFamily(familyId);
  }

  Family _mapToEntity(FamilyRow r) {
    return Family(
      id: r.id,
      name: r.name,
      description: r.description,
      notes: r.notes,
      createdAt: DateTime.tryParse(r.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r.updatedAt) ?? DateTime.now(),
      archivedAt: r.archivedAt != null ? DateTime.tryParse(r.archivedAt!) : null,
    );
  }
}
