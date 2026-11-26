import 'package:drift/drift.dart';
import '../../../domain/entities/entities.dart';
import '../app_database.dart';
import '../tables/people_table.dart';
import '../tables/entries_table.dart';
import '../migrations/schema_migrations.dart';

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
          ..where((t) => t.archivedAt.isNull() | t.archivedAt.equals(''))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  /// Watch all active people rows
  Stream<List<PersonRow>> watchActivePeople() {
    return (select(people)
          ..where((t) => t.archivedAt.isNull() | t.archivedAt.equals(''))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch();
  }

  /// Watch all archived people rows
  Stream<List<PersonRow>> watchArchivedPeople() {
    return (select(people)
          ..where((t) => t.archivedAt.isNotNull() & t.archivedAt.isNotValue(''))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .watch();
  }

  /// Search people by full name, phone number, address, or tags
  Future<List<PersonRow>> searchPeople(String query) {
    final pattern = '%$query%';
    return (select(people)
          ..where((t) =>
              (t.fullName.like(pattern) | t.phoneNumber.like(pattern) | t.address.like(pattern)) &
              (t.archivedAt.isNull() | t.archivedAt.equals('')))
          ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
        .get();
  }

  /// Get people belonging to a family
  Future<List<PersonRow>> getPeopleByFamily(String familyId) {
    return (select(people)
          ..where((t) => t.familyId.equals(familyId) & (t.archivedAt.isNull() | t.archivedAt.equals('')))
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

  Variable<String> _nullableString(String? val) {
    if (val == null || val.trim().isEmpty) {
      return const Variable<String>(null);
    }
    return Variable.withString(val.trim());
  }

  /// Save or update complete person with all extended columns, phones, and emails.
  /// Includes self-healing: if extended columns are missing, repairs schema and retries once.
  Future<void> saveExtendedPerson(Person person) async {
    try {
      await _saveExtendedPersonInternal(person);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('no column named') || msg.contains('table people has no column')) {
        // Extended columns missing on this DB instance; repair schema and retry
        await SchemaMigrations.ensureAllTablesAndColumns(db, Migrator(db));
        await _saveExtendedPersonInternal(person);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _saveExtendedPersonInternal(Person person) async {
    await transaction(() async {
      // 1. Upsert in people table (ON CONFLICT updates in-place without triggering FK DELETE cascades)
      await customInsert(
        '''
        INSERT INTO people (
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
        ON CONFLICT(id) DO UPDATE SET
          family_id = excluded.family_id,
          full_name = excluded.full_name,
          phone_number = excluded.phone_number,
          relationship_label = excluded.relationship_label,
          address = excluded.address,
          notes = excluded.notes,
          first_name = excluded.first_name,
          middle_name = excluded.middle_name,
          last_name = excluded.last_name,
          nickname = excluded.nickname,
          gender = excluded.gender,
          date_of_birth = excluded.date_of_birth,
          photo_path = excluded.photo_path,
          whatsapp_number = excluded.whatsapp_number,
          village = excluded.village,
          city = excluded.city,
          district = excluded.district,
          state = excluded.state,
          pin_code = excluded.pin_code,
          relationship_notes = excluded.relationship_notes,
          occupation = excluded.occupation,
          company = excluded.company,
          tags = excluded.tags,
          contact_source = excluded.contact_source,
          external_contact_id = excluded.external_contact_id,
          imported_at = excluded.imported_at,
          is_app_edited_after_import = excluded.is_app_edited_after_import,
          updated_at = excluded.updated_at,
          archived_at = excluded.archived_at
        ''',
        variables: [
          Variable.withString(person.id),
          _nullableString(person.familyId),
          Variable.withString(person.fullName.trim()),
          _nullableString(person.phoneNumber),
          _nullableString(person.relationshipLabel),
          _nullableString(person.address),
          _nullableString(person.notes),
          _nullableString(person.firstName),
          _nullableString(person.middleName),
          _nullableString(person.lastName),
          _nullableString(person.nickname),
          _nullableString(person.gender),
          _nullableString(person.dateOfBirth),
          _nullableString(person.photoPath),
          _nullableString(person.whatsappNumber),
          _nullableString(person.village),
          _nullableString(person.city),
          _nullableString(person.district),
          _nullableString(person.state),
          _nullableString(person.pinCode),
          _nullableString(person.relationshipNotes),
          _nullableString(person.occupation),
          _nullableString(person.company),
          _nullableString(person.tags.isNotEmpty ? person.tags.join(',') : null),
          Variable.withString(person.contactSource.trim().isNotEmpty ? person.contactSource : 'manual'),
          _nullableString(person.externalContactId),
          _nullableString(person.importedAt?.toIso8601String()),
          Variable.withInt(person.isAppEditedAfterImport ? 1 : 0),
          Variable.withString(person.createdAt.toIso8601String()),
          Variable.withString(person.updatedAt.toIso8601String()),
          _nullableString(person.archivedAt?.toIso8601String()),
        ],
        updates: {people},
      );

      // 2. Refresh secondary phone numbers cleanly
      await customStatement('DELETE FROM person_phones WHERE person_id = ?', [person.id]);
      final uniquePhones = person.secondaryPhones
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty && p != person.phoneNumber?.trim())
          .toSet()
          .toList();
      for (int i = 0; i < uniquePhones.length; i++) {
        await customInsert(
          '''
          INSERT INTO person_phones (id, person_id, phone_number, label, is_primary, created_at)
          VALUES (?, ?, ?, 'mobile', 0, datetime('now'))
          ''',
          variables: [
            Variable.withString('${person.id}_p$i'),
            Variable.withString(person.id),
            Variable.withString(uniquePhones[i]),
          ],
        );
      }

      // 3. Refresh emails cleanly
      await customStatement('DELETE FROM person_emails WHERE person_id = ?', [person.id]);
      final uniqueEmails = person.emails
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      for (int i = 0; i < uniqueEmails.length; i++) {
        await customInsert(
          '''
          INSERT INTO person_emails (id, person_id, email, label, is_primary, created_at)
          VALUES (?, ?, ?, 'email', 0, datetime('now'))
          ''',
          variables: [
            Variable.withString('${person.id}_e$i'),
            Variable.withString(person.id),
            Variable.withString(uniqueEmails[i]),
          ],
        );
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
            _nullableString(familyId),
            Variable.withString(id),
          ],
          updates: {people},
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
            updates: {people},
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
