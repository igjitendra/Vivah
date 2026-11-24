import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../database/app_database.dart';

enum DuplicateMatchType { none, phone, email, externalId, name }

class DuplicateMatchResult {
  final bool isDuplicate;
  final DuplicateMatchType matchType;
  final Person? existingPerson;
  final String? matchedValue;

  const DuplicateMatchResult({
    required this.isDuplicate,
    this.matchType = DuplicateMatchType.none,
    this.existingPerson,
    this.matchedValue,
  });
}

abstract class PeopleRepository {
  Future<List<Person>> getAllActivePeople();
  Stream<List<Person>> watchActivePeople();
  Stream<List<Person>> watchArchivedPeople();
  Future<List<Person>> searchPeople(String query);
  Future<Person?> getPersonById(String id);
  Future<void> createPerson(Person person);
  Future<void> updatePerson(Person person);
  Future<bool> canDeletePerson(String id);
  Future<bool> deletePersonSafely(String id);
  Future<void> archivePerson(String id);
  Future<void> restorePerson(String id);

  // Bulk Operations
  Future<int> importBatchContacts(List<ContactDraft> drafts, {String? defaultFamilyId, String? defaultRelationship});
  Future<void> bulkAssignFamily(List<String> personIds, String? familyId);
  Future<void> bulkAddTag(List<String> personIds, String tag);
  Future<void> bulkArchive(List<String> personIds);

  // Duplicate Resolution
  DuplicateMatchResult detectDuplicate(ContactDraft draft, List<Person> existingPeople);
  Future<void> mergePersonWithDraft(Person existing, ContactDraft incoming, Map<String, bool> keepIncomingField);
}

class DriftPeopleRepository implements PeopleRepository {
  final AppDatabase _db;

  DriftPeopleRepository(this._db);

  Future<List<Person>> _hydratePeopleBatch(List<PersonRow> rows) async {
    if (rows.isEmpty) return const [];
    return Future.wait(rows.map((r) async {
      final results = await Future.wait([
        _db.peopleDao.getExtendedColumns(r.id),
        _db.peopleDao.getPersonSecondaryPhones(r.id),
        _db.peopleDao.getPersonEmails(r.id),
      ]);
      return _mapToEntity(
        r,
        extended: results[0] as Map<String, dynamic>?,
        secondaryPhones: results[1] as List<String>?,
        emails: results[2] as List<String>?,
      );
    }));
  }

  @override
  Future<List<Person>> getAllActivePeople() async {
    final rows = await _db.peopleDao.getAllActivePeople();
    return _hydratePeopleBatch(rows);
  }

  @override
  Stream<List<Person>> watchActivePeople() {
    return _db.peopleDao.watchActivePeople().asyncMap(_hydratePeopleBatch);
  }

  @override
  Stream<List<Person>> watchArchivedPeople() {
    return _db.peopleDao.watchArchivedPeople().asyncMap(_hydratePeopleBatch);
  }

  @override
  Future<List<Person>> searchPeople(String query) async {
    final rows = await _db.peopleDao.searchPeople(query);
    return _hydratePeopleBatch(rows);
  }

  @override
  Future<Person?> getPersonById(String id) async {
    final row = await _db.peopleDao.getPersonById(id);
    if (row == null) return null;
    final results = await Future.wait([
      _db.peopleDao.getExtendedColumns(row.id),
      _db.peopleDao.getPersonSecondaryPhones(row.id),
      _db.peopleDao.getPersonEmails(row.id),
    ]);
    return _mapToEntity(
      row,
      extended: results[0] as Map<String, dynamic>?,
      secondaryPhones: results[1] as List<String>?,
      emails: results[2] as List<String>?,
    );
  }

  @override
  Future<void> createPerson(Person person) async {
    await _db.peopleDao.saveExtendedPerson(person);
  }

  @override
  Future<void> updatePerson(Person person) async {
    await _db.peopleDao.saveExtendedPerson(person);
  }

  @override
  Future<bool> canDeletePerson(String id) async {
    final entriesCount = await _db.peopleDao.countEntriesForPerson(id);
    return entriesCount == 0;
  }

  @override
  Future<bool> deletePersonSafely(String id) async {
    return _db.peopleDao.deletePersonSafely(id);
  }

  @override
  Future<void> archivePerson(String id) async {
    await _db.peopleDao.archivePerson(id);
  }

  @override
  Future<void> restorePerson(String id) async {
    await _db.peopleDao.restorePerson(id);
  }

  @override
  Future<int> importBatchContacts(
    List<ContactDraft> drafts, {
    String? defaultFamilyId,
    String? defaultRelationship,
  }) async {
    final now = DateTime.now();
    final people = drafts.map((d) {
      return Person(
        id: const Uuid().v4(),
        fullName: d.name.trim().isNotEmpty ? d.name.trim() : 'अज्ञात संपर्क',
        firstName: d.firstName,
        middleName: d.middleName,
        lastName: d.lastName,
        nickname: d.nickname,
        phoneNumber: d.primaryPhone,
        secondaryPhones: d.secondaryPhones,
        emails: d.emails,
        address: d.address,
        village: d.village,
        city: d.city,
        district: d.district,
        state: d.state,
        pinCode: d.pinCode,
        company: d.company,
        occupation: d.jobTitle,
        familyId: defaultFamilyId,
        relationshipLabel: defaultRelationship,
        contactSource: 'phone_import',
        externalContactId: d.externalId,
        importedAt: now,
        notes: d.notes,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    return _db.peopleDao.insertBatchPeople(people);
  }

  @override
  Future<void> bulkAssignFamily(List<String> personIds, String? familyId) {
    return _db.peopleDao.bulkAssignFamily(personIds, familyId);
  }

  @override
  Future<void> bulkAddTag(List<String> personIds, String tag) {
    return _db.peopleDao.bulkAddTag(personIds, tag);
  }

  @override
  Future<void> bulkArchive(List<String> personIds) {
    return _db.peopleDao.bulkArchive(personIds);
  }

  @override
  DuplicateMatchResult detectDuplicate(ContactDraft draft, List<Person> existingPeople) {
    // 1. Match by External Contact ID if present
    if (draft.externalId != null && draft.externalId!.isNotEmpty) {
      for (final p in existingPeople) {
        if (p.externalContactId == draft.externalId) {
          return DuplicateMatchResult(
            isDuplicate: true,
            matchType: DuplicateMatchType.externalId,
            existingPerson: p,
            matchedValue: draft.externalId,
          );
        }
      }
    }

    // 2. Match by normalized phone number
    final draftPhones = draft.phones.map(_normalizePhone).where((p) => p.length >= 7).toList();
    if (draftPhones.isNotEmpty) {
      for (final p in existingPeople) {
        final existingPhones = p.allPhoneNumbers.map(_normalizePhone).where((phone) => phone.length >= 7).toList();
        for (final dp in draftPhones) {
          for (final ep in existingPhones) {
            if (dp == ep || (dp.length >= 10 && ep.length >= 10 && (dp.endsWith(ep.substring(ep.length - 10)) || ep.endsWith(dp.substring(dp.length - 10))))) {
              return DuplicateMatchResult(
                isDuplicate: true,
                matchType: DuplicateMatchType.phone,
                existingPerson: p,
                matchedValue: p.phoneNumber ?? dp,
              );
            }
          }
        }
      }
    }

    // 3. Match by normalized email
    final draftEmails = draft.emails.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
    if (draftEmails.isNotEmpty) {
      for (final p in existingPeople) {
        final existingEmails = p.emails.map((e) => e.trim().toLowerCase()).toList();
        for (final de in draftEmails) {
          if (existingEmails.contains(de)) {
            return DuplicateMatchResult(
              isDuplicate: true,
              matchType: DuplicateMatchType.email,
              existingPerson: p,
              matchedValue: de,
            );
          }
        }
      }
    }

    // 4. Secondary match: exact name match
    final cleanDraftName = draft.name.trim().toLowerCase();
    if (cleanDraftName.isNotEmpty) {
      for (final p in existingPeople) {
        if (p.fullName.trim().toLowerCase() == cleanDraftName) {
          return DuplicateMatchResult(
            isDuplicate: true,
            matchType: DuplicateMatchType.name,
            existingPerson: p,
            matchedValue: p.fullName,
          );
        }
      }
    }

    return const DuplicateMatchResult(isDuplicate: false);
  }

  @override
  Future<void> mergePersonWithDraft(
    Person existing,
    ContactDraft incoming,
    Map<String, bool> keepIncomingField,
  ) async {
    // Merge phones without dropping existing ones
    final combinedPhones = List<String>.from(existing.allPhoneNumbers);
    for (final p in incoming.phones) {
      final clean = p.trim();
      if (clean.isNotEmpty && !combinedPhones.contains(clean)) {
        combinedPhones.add(clean);
      }
    }

    // Merge emails without dropping existing ones
    final combinedEmails = List<String>.from(existing.emails);
    for (final e in incoming.emails) {
      final clean = e.trim();
      if (clean.isNotEmpty && !combinedEmails.contains(clean)) {
        combinedEmails.add(clean);
      }
    }

    final mergedPerson = existing.copyWith(
      fullName: (keepIncomingField['name'] == true && incoming.name.trim().isNotEmpty)
          ? incoming.name.trim()
          : existing.fullName,
      phoneNumber: (keepIncomingField['phone'] == true && incoming.primaryPhone != null)
          ? incoming.primaryPhone
          : existing.phoneNumber,
      secondaryPhones: combinedPhones.where((p) => p != (keepIncomingField['phone'] == true ? incoming.primaryPhone : existing.phoneNumber)).toList(),
      emails: combinedEmails,
      address: (keepIncomingField['address'] == true && incoming.address != null)
          ? incoming.address
          : (existing.address ?? incoming.address),
      village: (keepIncomingField['address'] == true && incoming.village != null)
          ? incoming.village
          : (existing.village ?? incoming.village),
      city: (keepIncomingField['address'] == true && incoming.city != null)
          ? incoming.city
          : (existing.city ?? incoming.city),
      occupation: (keepIncomingField['job'] == true && incoming.jobTitle != null)
          ? incoming.jobTitle
          : (existing.occupation ?? incoming.jobTitle),
      company: (keepIncomingField['company'] == true && incoming.company != null)
          ? incoming.company
          : (existing.company ?? incoming.company),
      externalContactId: existing.externalContactId ?? incoming.externalId,
      updatedAt: DateTime.now(),
    );

    await updatePerson(mergedPerson);
  }

  String _normalizePhone(String raw) {
    var clean = raw.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (clean.startsWith('91') && clean.length > 10) {
      clean = clean.substring(2);
    }
    if (clean.startsWith('0') && clean.length > 10) {
      clean = clean.substring(1);
    }
    return clean;
  }

  Person _mapToEntity(
    PersonRow r, {
    Map<String, dynamic>? extended,
    List<String> secondaryPhones = const [],
    List<String> emails = const [],
  }) {
    final tagsStr = extended?['tags'] as String?;
    final tagsList = tagsStr != null && tagsStr.isNotEmpty
        ? tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    return Person(
      id: r.id,
      familyId: r.familyId != null && r.familyId!.isNotEmpty ? r.familyId : null,
      fullName: r.fullName,
      firstName: extended?['first_name'] as String?,
      middleName: extended?['middle_name'] as String?,
      lastName: extended?['last_name'] as String?,
      nickname: extended?['nickname'] as String?,
      gender: extended?['gender'] as String?,
      dateOfBirth: extended?['date_of_birth'] as String?,
      photoPath: extended?['photo_path'] as String?,
      phoneNumber: r.phoneNumber != null && r.phoneNumber!.isNotEmpty ? r.phoneNumber : null,
      secondaryPhones: secondaryPhones,
      whatsappNumber: extended?['whatsapp_number'] as String?,
      emails: emails,
      address: r.address != null && r.address!.isNotEmpty ? r.address : null,
      village: extended?['village'] as String? ?? (r.address != null && r.address!.isNotEmpty ? r.address : null),
      city: extended?['city'] as String?,
      district: extended?['district'] as String?,
      state: extended?['state'] as String?,
      pinCode: extended?['pin_code'] as String?,
      relationshipLabel: r.relationshipLabel != null && r.relationshipLabel!.isNotEmpty ? r.relationshipLabel : null,
      relationshipNotes: extended?['relationship_notes'] as String?,
      notes: r.notes != null && r.notes!.isNotEmpty ? r.notes : null,
      occupation: extended?['occupation'] as String?,
      company: extended?['company'] as String?,
      tags: tagsList,
      contactSource: extended?['contact_source'] as String? ?? 'manual',
      externalContactId: extended?['external_contact_id'] as String?,
      importedAt: extended?['imported_at'] != null ? DateTime.tryParse(extended!['imported_at'] as String) : null,
      isAppEditedAfterImport: (extended?['is_app_edited_after_import'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(r.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(r.updatedAt) ?? DateTime.now(),
      archivedAt: r.archivedAt != null && r.archivedAt!.isNotEmpty ? DateTime.tryParse(r.archivedAt!) : null,
    );
  }
}
