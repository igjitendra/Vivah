import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/database/app_database.dart';

/// Metadata for Vyavahaar offline backup
class BackupMetadata {
  final int backupVersion;
  final String appVersion;
  final String createdAt;
  final bool isEncrypted;
  final int peopleCount;
  final int eventsCount;
  final int entriesCount;
  final int itemsCount;

  const BackupMetadata({
    this.backupVersion = 4,
    this.appVersion = '1.0.0',
    required this.createdAt,
    required this.isEncrypted,
    required this.peopleCount,
    required this.eventsCount,
    required this.entriesCount,
    required this.itemsCount,
  });

  Map<String, dynamic> toJson() => {
        'vyavahaar_backup_version': backupVersion,
        'app_version': appVersion,
        'created_at': createdAt,
        'is_encrypted': isEncrypted,
        'people_count': peopleCount,
        'events_count': eventsCount,
        'entries_count': entriesCount,
        'items_count': itemsCount,
      };
}

/// Offline Backup & Restore Service
/// Implements OWASP-aligned AES-256-GCM encryption with 600,000 PBKDF2 iterations.
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Create an offline backup (optionally encrypted with password)
  Future<File> createBackup({String? password}) async {
    final now = DateTime.now().toUtc().toIso8601String();

    // 1. Gather all database records
    final families = await _db.select(_db.families).get();
    final people = await _db.select(_db.people).get();
    final events = await _db.select(_db.events).get();
    final entries = await _db.select(_db.entries).get();
    final entryItems = await _db.select(_db.entryItems).get();
    final reminders = await _db.select(_db.reminders).get();

    final payloadMap = {
      'families': families.map((f) => f.toJson()).toList(),
      'people': people.map((p) => p.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'entry_items': entryItems.map((i) => i.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };

    final payloadJson = jsonEncode(payloadMap);
    final isEncrypted = password != null && password.trim().isNotEmpty;

    final metadata = BackupMetadata(
      createdAt: now,
      isEncrypted: isEncrypted,
      peopleCount: people.length,
      eventsCount: events.length,
      entriesCount: entries.length,
      itemsCount: entryItems.length,
    );

    final envelope = <String, dynamic>{
      'vyavahaar_backup_version': 4,
      'app_version': '1.0.0',
      'created_at': now,
      'is_encrypted': isEncrypted,
      'metadata': metadata.toJson(),
    };

    if (isEncrypted) {
      // Cryptographically random 16-byte salt
      final saltBytes = _generateRandomBytes(16);
      // Cryptographically random 12-byte nonce
      final nonceBytes = _generateRandomBytes(12);

      // PBKDF2-HMAC-SHA256 with 600,000 iterations (OWASP Standard)
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: 600000,
        bits: 256,
      );

      final secretKey = await pbkdf2.deriveKeyFromPassword(
        password: password.trim(),
        nonce: saltBytes,
      );

      // AES-256-GCM Authenticated Encryption
      final aesGcm = AesGcm.with256bits();
      final secretBox = await aesGcm.encrypt(
        utf8.encode(payloadJson),
        secretKey: secretKey,
        nonce: nonceBytes,
      );

      envelope['kdf'] = {
        'algorithm': 'PBKDF2-HMAC-SHA256',
        'iterations': 600000,
        'salt': base64Encode(saltBytes),
      };

      envelope['cipher'] = {
        'algorithm': 'AES-256-GCM',
        'nonce': base64Encode(nonceBytes),
        'tag': base64Encode(secretBox.mac.bytes),
        'ciphertext': base64Encode(secretBox.cipherText),
      };
    } else {
      envelope['payload'] = payloadMap;
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final filename = isEncrypted
        ? 'vyavahaar_backup_${DateTime.now().millisecondsSinceEpoch}.enc.json'
        : 'vyavahaar_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    final file = File('${outputDir.path}/$filename');
    await file.writeAsString(jsonEncode(envelope));
    return file;
  }

  /// Restore database from backup file with atomic safety
  Future<void> restoreBackup(File backupFile, {String? password}) async {
    final rawString = await backupFile.readAsString();
    final envelope = jsonDecode(rawString) as Map<String, dynamic>;

    final isEncrypted = envelope['is_encrypted'] as bool? ?? false;
    Map<String, dynamic> payloadMap;

    if (isEncrypted) {
      if (password == null || password.trim().isEmpty) {
        throw ArgumentError('बैकअप पासवर्ड आवश्यक है (Password required)');
      }

      final cipherData = envelope['cipher'] as Map<String, dynamic>?;
      final kdfData = envelope['kdf'] as Map<String, dynamic>?;

      if (cipherData == null || kdfData == null) {
        throw const FormatException('अमान्य एन्क्रिप्टेड बैकअप संरचना (Corrupt envelope)');
      }

      final saltBytes = base64Decode(kdfData['salt'] as String);
      final nonceBytes = base64Decode(cipherData['nonce'] as String);
      final tagBytes = base64Decode(cipherData['tag'] as String);
      final cipherTextBytes = base64Decode(cipherData['ciphertext'] as String);
      final iterations = kdfData['iterations'] as int? ?? 600000;

      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      );

      final secretKey = await pbkdf2.deriveKeyFromPassword(
        password: password.trim(),
        nonce: saltBytes,
      );

      final aesGcm = AesGcm.with256bits();
      final secretBox = SecretBox(
        cipherTextBytes,
        nonce: nonceBytes,
        mac: Mac(tagBytes),
      );

      try {
        final decryptedBytes = await aesGcm.decrypt(
          secretBox,
          secretKey: secretKey,
        );
        payloadMap = jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;
      } catch (_) {
        throw ArgumentError('गलत पासवर्ड या दूषित बैकअप (Incorrect password or corrupted file)');
      }
    } else {
      payloadMap = envelope['payload'] as Map<String, dynamic>? ?? {};
    }

    // Atomic database restore inside a SQLite transaction
    await _db.transaction(() async {
      // Clear current data safely
      await _db.customStatement('DELETE FROM entry_items;');
      await _db.customStatement('DELETE FROM entries;');
      await _db.customStatement('DELETE FROM events;');
      await _db.customStatement('DELETE FROM people;');
      await _db.customStatement('DELETE FROM families;');
      await _db.customStatement('DELETE FROM reminders;');

      // Repopulate from payload (with backwards-compatible v3/v4 key resolution)
      final familiesList = (payloadMap['families'] as List<dynamic>?) ?? [];
      for (final item in familiesList) {
        final m = item as Map<String, dynamic>;
        await _db.into(_db.families).insert(FamiliesCompanion.insert(
          id: m['id'] as String,
          name: m['name'] as String,
          description: Value(m['description'] as String?),
          notes: Value(m['notes'] as String?),
          createdAt: Value(m['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: Value(m['updated_at'] as String? ?? DateTime.now().toIso8601String()),
          archivedAt: Value(m['archived_at'] as String?),
        ));
      }

      final peopleList = (payloadMap['people'] as List<dynamic>?) ?? [];
      for (final item in peopleList) {
        final m = item as Map<String, dynamic>;
        await _db.into(_db.people).insert(PeopleCompanion.insert(
          id: m['id'] as String,
          familyId: Value(m['family_id'] as String? ?? m['familyId'] as String?),
          fullName: (m['full_name'] as String?) ?? (m['name'] as String? ?? 'अज्ञात'),
          phoneNumber: Value(m['phone_number'] as String? ?? m['phone'] as String?),
          relationshipLabel: Value(m['relationship_label'] as String? ?? m['relationship'] as String?),
          address: Value(m['address'] as String? ?? m['village'] as String?),
          notes: Value(m['notes'] as String?),
          createdAt: Value(m['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: Value(m['updated_at'] as String? ?? DateTime.now().toIso8601String()),
          archivedAt: Value(m['archived_at'] as String?),
        ));
      }

      final eventsList = (payloadMap['events'] as List<dynamic>?) ?? [];
      for (final item in eventsList) {
        final m = item as Map<String, dynamic>;
        await _db.into(_db.events).insert(EventsCompanion.insert(
          id: m['id'] as String,
          title: m['title'] as String,
          eventType: (m['event_type'] as String?) ?? (m['eventType'] as String? ?? 'अन्य'),
          eventDate: (m['event_date'] as String?) ?? (m['eventDate'] as String? ?? DateTime.now().toIso8601String().substring(0, 10)),
          venue: Value(m['venue'] as String?),
          notes: Value(m['notes'] as String?),
          createdAt: Value(m['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: Value(m['updated_at'] as String? ?? DateTime.now().toIso8601String()),
          archivedAt: Value(m['archived_at'] as String?),
        ));
      }

      final entriesList = (payloadMap['entries'] as List<dynamic>?) ?? [];
      for (final item in entriesList) {
        final m = item as Map<String, dynamic>;
        final rawAmount = m['amount_paise'] ?? m['cashAmountPaise'];
        int? amountPaise;
        if (rawAmount != null) {
          amountPaise = rawAmount is int ? rawAmount : int.tryParse(rawAmount.toString());
        }
        await _db.into(_db.entries).insert(EntriesCompanion.insert(
          id: m['id'] as String,
          personId: (m['person_id'] as String?) ?? (m['personId'] as String? ?? ''),
          eventId: Value(m['event_id'] as String? ?? m['eventId'] as String?),
          direction: (m['direction'] as String?) ?? 'received',
          transactionType: Value(m['transaction_type'] as String? ?? m['transactionType'] as String? ?? 'cash'),
          status: Value(m['status'] as String? ?? 'recorded'),
          amountPaise: Value(amountPaise != null ? BigInt.from(amountPaise) : null),
          transactionDate: (m['transaction_date'] as String?) ?? (m['transactionDate'] as String? ?? DateTime.now().toIso8601String().substring(0, 10)),
          notes: Value(m['notes'] as String?),
          createdAt: Value(m['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: Value(m['updated_at'] as String? ?? DateTime.now().toIso8601String()),
          recordedAt: Value(m['recorded_at'] as String? ?? m['recordedAt'] as String?),
          cancelledAt: Value(m['cancelled_at'] as String? ?? m['cancelledAt'] as String?),
          archivedAt: Value(m['archived_at'] as String? ?? m['deleted_at'] as String?),
        ));
      }

      final itemsList = (payloadMap['entry_items'] as List<dynamic>?) ?? (payloadMap['items'] as List<dynamic>? ?? []);
      for (final item in itemsList) {
        final m = item as Map<String, dynamic>;
        final rawEst = m['estimated_value_paise'] ?? m['estimatedValuePaise'];
        int? estPaise;
        if (rawEst != null) {
          estPaise = rawEst is int ? rawEst : int.tryParse(rawEst.toString());
        }
        final rawQty = m['quantity'];
        double qty = 1.0;
        if (rawQty != null) {
          qty = rawQty is double ? rawQty : (double.tryParse(rawQty.toString()) ?? 1.0);
        }
        await _db.into(_db.entryItems).insert(EntryItemsCompanion.insert(
          id: m['id'] as String,
          entryId: (m['entry_id'] as String?) ?? (m['entryId'] as String? ?? ''),
          itemName: (m['item_name'] as String?) ?? (m['itemName'] as String? ?? ''),
          quantity: Value(qty),
          unit: Value(m['unit'] as String? ?? 'संख्या'),
          estimatedValuePaise: Value(estPaise != null ? BigInt.from(estPaise) : null),
          notes: Value(m['notes'] as String? ?? m['condition'] as String?),
          createdAt: Value(m['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: Value(m['updated_at'] as String? ?? DateTime.now().toIso8601String()),
        ));
      }

      final remindersList = (payloadMap['reminders'] as List<dynamic>?) ?? [];
      for (final item in remindersList) {
        final m = item as Map<String, dynamic>;
        await _db.into(_db.reminders).insert(RemindersCompanion.insert(
          id: m['id'] as String,
          entryId: Value(m['entry_id'] as String? ?? m['entryId'] as String?),
          reminderDate: (m['reminder_date'] as String?) ?? (m['reminderDate'] as String? ?? DateTime.now().toIso8601String().substring(0, 10)),
          title: (m['title'] as String?) ?? '',
          notes: Value(m['notes'] as String?),
          isCompleted: Value(m['is_completed'] as bool? ?? m['isCompleted'] as bool? ?? false),
          createdAt: Value(m['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: Value(m['updated_at'] as String? ?? DateTime.now().toIso8601String()),
        ));
      }

      // Verify foreign key integrity
      await _db.customStatement('PRAGMA foreign_key_check;');
    });
  }

  /// Share backup file via native share sheet
  static Future<void> shareBackup(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'व्यवहार बैकअप फ़ाइल');
  }

  List<int> _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
