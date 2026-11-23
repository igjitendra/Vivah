import 'package:drift/drift.dart';
import '../../../domain/entities/entities.dart';
import '../app_database.dart';
import '../tables/people_table.dart';
import '../tables/entries_table.dart';

part 'people_dao.g.dart';

/// DAO for People table & Advanced Phone Contacts Import sub-system.
/// 100% offline, transactional, and foreign-key safe.
@DriftAccessor(tables: [People, Entries])
class PeopleDao extends DatabaseAccessor<AppDatabase> with _$PeopleDaoMixin {
  PeopleDao(super.db);

  /// Get basic person row by ID
  Future<PersonRow?> getPersonById(String id) {
    return (select(people)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get all active (non-archived) people rows
  Future<List<PersonRow>> getAllActivePeople() {
    return (select(people)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  /// Watch all active people rows
  Stream<List<PersonRow>> watchActivePeople() {
    return (select(people)
          ..where((t) => t.archivedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch();
  }

  /// Watch all archived people rows
  Stream<List<PersonRow>> watchArchivedPeople() {
    return (select(people)
          ..where((t) => t.archivedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch();
  }

  /// Search people by full name, phone number, address, or tags
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

  /// Count transactions associated with this person (used to enforce deletion protection)
  Future<int> countEntriesForPerson(String personId) async {
    final count = entries.id.count();
    final row = await (selectOnly(entries)
          ..addColumns([count])
          ..where(entries.personId.equals(personId) & entries.archivedAt.isNull()))
        .getSingleOrNull();
    return row?.read(count) ?? 0;
  }

  /// Insert new basic person
  Future<int> insertPerson(PeopleCompanion person) {
    return into(people).insert(person);
  }

  /// Update basic person
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

  /// Restore an archived person
  Future<int> restorePerson(String id) {
    return (update(people)..where((t) => t.id.equals(id))).write(
      PeopleCompanion(
        archivedAt: const Value(null),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  // =========================================================================
  // Schema v6: Extended Person Attributes & Contact Management
  // =========================================================================

  /// Reads extended columns for a given person ID
  Future<Map<String, dynamic>?> getExtendedColumns(String id) async {
    try {
      final rows = await customSelect(
        '''
        SELECT first_name, middle_name, last_name, nickname, gender, date_of_birth,
               photo_path, whatsapp_number, village, city, district, state, pin_code,
               relationship_notes, occupation, company, tags, contact_source,
               external_contact_id, imported_at, is_app_edited_after_import
        FROM people WHERE id = ?
        ''',
        variables: [Variable.withString(id)],
      ).get();

      if (rows.isEmpty) return null;
      return rows.first.data;
    } catch (_) {
      return null;
    }
  }

  /// Fetch secondary phone numbers for a person
  Future<List<String>> getPersonSecondaryPhones(String personId) async {
    try {
      final rows = await customSelect(
        'SELECT phone_number FROM person_phones WHERE person_id = ? ORDER BY is_primary DESC, created_at ASC',
        variables: [Variable.withString(personId)],
      ).get();
      return rows.map((r) => r.read<String>('phone_number')).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch email addresses for a person
  Future<List<String>> getPersonEmails(String personId) async {
    try {
      final rows = await customSelect(
        'SELECT email FROM person_emails WHERE person_id = ? ORDER BY is_primary DESC, created_at ASC',
        variables: [Variable.withString(personId)],
      ).get();
      return rows.map((r) => r.read<String>('email')).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save or update complete person with all extended columns, phones, and emails
  Future<void> saveExtendedPerson(Person person) async {
    await transaction(() async {
      // 1. Insert or replace in people table
      await customInsert(
        '''
        INSERT OR REPLACE INTO people (
          id, family_id, full_name, phone_number, relationship_label, address, notes,
          first_name, middle_name, last_name, nickname, gender, date_of_birth, photo_path,
          whatsapp_number, village, city, district, state, pin_code, relationship_notes,
          occupation, company, tags, contact_source, external_contact_id, imported_at,
          is_app_edited_after_import, created_at, updated_at, archived_at
        ) VALUES (
          ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?
        )
        ''',
        variables: [
          Variable.withString(person.id),
          Variable.withString(person.familyId ?? ''),
          Variable.withString(person.fullName),
          Variable.withString(person.phoneNumber ?? ''),
          Variable.withString(person.relationshipLabel ?? ''),
          Variable.withString(person.address ?? ''),
          Variable.withString(person.notes ?? ''),
          Variable.withString(person.firstName ?? ''),
          Variable.withString(person.middleName ?? ''),
          Variable.withString(person.lastName ?? ''),
          Variable.withString(person.nickname ?? ''),
          Variable.withString(person.gender ?? ''),
          Variable.withString(person.dateOfBirth ?? ''),
          Variable.withString(person.photoPath ?? ''),
          Variable.withString(person.whatsappNumber ?? ''),
          Variable.withString(person.village ?? ''),
          Variable.withString(person.city ?? ''),
          Variable.withString(person.district ?? ''),
          Variable.withString(person.state ?? ''),
          Variable.withString(person.pinCode ?? ''),
          Variable.withString(person.relationshipNotes ?? ''),
          Variable.withString(person.occupation ?? ''),
          Variable.withString(person.company ?? ''),
          Variable.withString(person.tags.join(',')),
          Variable.withString(person.contactSource),
          Variable.withString(person.externalContactId ?? ''),
          Variable.withString(person.importedAt?.toIso8601String() ?? ''),
          Variable.withInt(person.isAppEditedAfterImport ? 1 : 0),
          Variable.withString(person.createdAt.toIso8601String()),
          Variable.withString(person.updatedAt.toIso8601String()),
          Variable.withString(person.archivedAt?.toIso8601String() ?? ''),
        ],
      );

      // 2. Refresh secondary phone numbers
      await customStatement('DELETE FROM person_phones WHERE person_id = ?', [person.id]);
      for (final phone in person.secondaryPhones) {
        if (phone.trim().isNotEmpty && phone.trim() != person.phoneNumber?.trim()) {
          await customInsert(
            '''
            INSERT INTO person_phones (id, person_id, phone_number, label, is_primary, created_at)
            VALUES (?, ?, ?, 'mobile', 0, datetime('now'))
            ''',
            variables: [
              Variable.withString('${person.id}_${phone.hashCode}'),
              Variable.withString(person.id),
              Variable.withString(phone.trim()),
            ],
          );
        }
      }

      // 3. Refresh emails
      await customStatement('DELETE FROM person_emails WHERE person_id = ?', [person.id]);
      for (final email in person.emails) {
        if (email.trim().isNotEmpty) {
          await customInsert(
            '''
            INSERT INTO person_emails (id, person_id, email, label, is_primary, created_at)
            VALUES (?, ?, ?, 'email', 0, datetime('now'))
            ''',
            variables: [
              Variable.withString('${person.id}_${email.hashCode}'),
              Variable.withString(person.id),
              Variable.withString(email.trim()),
            ],
          );
        }
      }
    });
  }

  /// Batch insert imported contacts efficiently in a single database transaction
  Future<int> insertBatchPeople(List<Person> peopleList) async {
    int insertedCount = 0;
    await transaction(() async {
      for (final person in peopleList) {
        await saveExtendedPerson(person);
        insertedCount++;
      }
    });
    return insertedCount;
  }

  /// Bulk assign people to a family
  Future<void> bulkAssignFamily(List<String> personIds, String? familyId) async {
    await transaction(() async {
      for (final id in personIds) {
        await customUpdate(
          'UPDATE people SET family_id = ?, updated_at = datetime("now") WHERE id = ?',
          variables: [
            Variable.withString(familyId ?? ''),
            Variable.withString(id),
          ],
        );
      }
    });
  }

  /// Bulk add a tag to people
  Future<void> bulkAddTag(List<String> personIds, String tag) async {
    await transaction(() async {
      for (final id in personIds) {
        final ext = await getExtendedColumns(id);
        final existingTags = (ext?['tags'] as String?)?.split(',').where((t) => t.trim().isNotEmpty).toList() ?? [];
        if (!existingTags.contains(tag)) {
          existingTags.add(tag);
          await customUpdate(
            'UPDATE people SET tags = ?, updated_at = datetime("now") WHERE id = ?',
            variables: [
              Variable.withString(existingTags.join(',')),
              Variable.withString(id),
            ],
          );
        }
      }
    });
  }

  /// Bulk archive people
  Future<void> bulkArchive(List<String> personIds) async {
    await transaction(() async {
      for (final id in personIds) {
        await archivePerson(id);
      }
    });
  }

  /// Safe deletion preserving financial records:
  /// If the person is referenced in `entries`, do NOT delete; soft-archive instead to safeguard financial history!
  Future<bool> deletePersonSafely(String id) async {
    final entryCount = await countEntriesForPerson(id);
    if (entryCount > 0) {
      // Soft-archive to preserve historical financial ledger integrity
      await archivePerson(id);
      return false; // Indicating soft-archival rather than hard deletion
    }

    await transaction(() async {
      await customStatement('DELETE FROM person_phones WHERE person_id = ?', [id]);
      await customStatement('DELETE FROM person_emails WHERE person_id = ?', [id]);
      await (delete(people)..where((t) => t.id.equals(id))).go();
    });
    return true;
  }

  /// Duplicate Detection: Find person by phone number (checks primary and secondary)
  Future<String?> findPersonIdByPhone(String cleanPhone) async {
    try {
      // 1. Check primary phone
      final primaryRows = await customSelect(
        '''
        SELECT id FROM people
        WHERE archived_at IS NULL
          AND REPLACE(REPLACE(REPLACE(REPLACE(phone_number, ' ', ''), '-', ''), '(', ''), ')', '') LIKE ?
        LIMIT 1
        ''',
        variables: [Variable.withString('%$cleanPhone')],
      ).get();

      if (primaryRows.isNotEmpty) {
        return primaryRows.first.read<String>('id');
      }

      // 2. Check secondary phones
      final secondaryRows = await customSelect(
        '''
        SELECT person_id FROM person_phones
        WHERE REPLACE(REPLACE(REPLACE(REPLACE(phone_number, ' ', ''), '-', ''), '(', ''), ')', '') LIKE ?
        LIMIT 1
        ''',
        variables: [Variable.withString('%$cleanPhone')],
      ).get();

      if (secondaryRows.isNotEmpty) {
        return secondaryRows.first.read<String>('person_id');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Duplicate Detection: Find person by email
  Future<String?> findPersonIdByEmail(String email) async {
    try {
      final rows = await customSelect(
        'SELECT person_id FROM person_emails WHERE LOWER(email) = LOWER(?) LIMIT 1',
        variables: [Variable.withString(email.trim())],
      ).get();
      if (rows.isNotEmpty) {
        return rows.first.read<String>('person_id');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Duplicate Detection: Find person by external contact ID
  Future<String?> findPersonIdByExternalId(String externalId) async {
    try {
      final rows = await customSelect(
        'SELECT id FROM people WHERE external_contact_id = ? AND archived_at IS NULL LIMIT 1',
        variables: [Variable.withString(externalId)],
      ).get();
      if (rows.isNotEmpty) {
        return rows.first.read<String>('id');
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
