import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/migrations/schema_migrations.dart';

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
  final int imagesCount;

  const BackupMetadata({
    this.backupVersion = 5,
    this.appVersion = '1.0.14',
    required this.createdAt,
    required this.isEncrypted,
    required this.peopleCount,
    required this.eventsCount,
    required this.entriesCount,
    required this.itemsCount,
    this.imagesCount = 0,
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
        'images_count': imagesCount,
      };
}

/// Summary returned by inspecting a backup file prior to restore.
class BackupInspection {
  final bool isZip;
  final bool isEncrypted;
  final int backupVersion;
  final String? createdAt;
  final int peopleCount;
  final int eventsCount;
  final int entriesCount;
  final int itemsCount;
  final int imagesCount;

  const BackupInspection({
    required this.isZip,
    required this.isEncrypted,
    required this.backupVersion,
    this.createdAt,
    this.peopleCount = 0,
    this.eventsCount = 0,
    this.entriesCount = 0,
    this.itemsCount = 0,
    this.imagesCount = 0,
  });
}

/// Detailed result returned after creating a ZIP backup.
class BackupCreateResult {
  final File file;
  final BackupMetadata metadata;
  final int fileSizeBytes;

  const BackupCreateResult({
    required this.file,
    required this.metadata,
    required this.fileSizeBytes,
  });
}

/// Detailed result returned after restoring a backup.
class BackupRestoreResult {
  final int peopleRestored;
  final int eventsRestored;
  final int entriesRestored;
  final int itemsRestored;
  final int imagesRestored;

  const BackupRestoreResult({
    required this.peopleRestored,
    required this.eventsRestored,
    required this.entriesRestored,
    required this.itemsRestored,
    required this.imagesRestored,
  });
}

/// Offline Complete ZIP Backup & One-Shot Restore Service.
/// Packages ALL SQLite tables + ALL local images (gift item photos, proof photos,
/// family avatars, people photos, event attachments) into a single portable .zip file,
/// with optional OWASP AES-256-GCM + 600k-PBKDF2 encryption.
class BackupService {
  static const String _zipAssetPrefix = 'zip_asset:';
  static const int _pbkdf2Iterations = 600000;

  /// Insertion order respecting all SQLite foreign keys (parents before children).
  static const List<String> _restoreTableOrder = [
    'families',
    'people',
    'person_phones',
    'person_emails',
    'events',
    'event_functions',
    'event_participants',
    'event_guests',
    'event_tasks',
    'event_schedule_items',
    'event_budget_categories',
    'event_notes',
    'event_attachments',
    'event_activity_logs',
    'event_reminders',
    'entries',
    'entry_items',
    'attachments',
    'reminders',
    'app_settings',
  ];

  final AppDatabase _db;

  BackupService(this._db);

  /// Creates a portable ZIP backup containing all app data + compressed images.
  Future<File> createBackup({
    String? password,
    Directory? overrideBaseDir,
  }) async {
    final res = await createZipBackup(
      password: password,
      overrideBaseDir: overrideBaseDir,
    );
    return res.file;
  }

  /// Creates a complete ZIP backup and returns metadata + file size summary.
  Future<BackupCreateResult> createZipBackup({
    String? password,
    Directory? overrideBaseDir,
  }) async {
    await SchemaMigrations.ensureAllTablesAndColumns(_db);
    final baseDir = overrideBaseDir ?? await getApplicationDocumentsDirectory();
    final now = DateTime.now().toUtc().toIso8601String();
    final trimmedPassword = password?.trim() ?? '';
    final isEncrypted = trimmedPassword.isNotEmpty;

    // 1. Export all tables completely
    final Map<String, List<Map<String, dynamic>>> tableDump = {};
    for (final table in _restoreTableOrder) {
      tableDump[table] = await _safeSelectTable(table);
    }

    // 2. Collect all image assets referenced in DB & settings and rewrite to portable zip keys
    final Map<String, File> archiveImageSources = {};
    final Map<String, String> originalPathToAssetUri = {};
    final Set<String> usedRelPaths = {};

    String? registerImage(String? rawPath, String defaultSubdir) {
      if (rawPath == null || rawPath.trim().isEmpty) return null;
      final trimmed = rawPath.trim();
      if (trimmed.startsWith(_zipAssetPrefix)) return trimmed;

      final existingMapped = originalPathToAssetUri[trimmed];
      if (existingMapped != null) return existingMapped;

      final file = _resolveExistingImageFile(trimmed, baseDir, defaultSubdir);
      if (file == null) return null;

      var relPath = '$defaultSubdir/${p.basename(file.path)}';
      if (usedRelPaths.contains(relPath)) {
        final stem = p.basenameWithoutExtension(file.path);
        final ext = p.extension(file.path);
        relPath = '$defaultSubdir/${stem}_${usedRelPaths.length}$ext';
      }
      usedRelPaths.add(relPath);

      final assetUri = '$_zipAssetPrefix$relPath';
      originalPathToAssetUri[trimmed] = assetUri;
      archiveImageSources[relPath] = file;
      return assetUri;
    }

    void rewriteRowPath(
      List<Map<String, dynamic>> rows,
      String column,
      String subdir,
    ) {
      for (final row in rows) {
        final val = row[column];
        if (val is String && val.isNotEmpty) {
          final rewritten = registerImage(val, subdir);
          if (rewritten != null) {
            row[column] = rewritten;
          }
        }
      }
    }

    rewriteRowPath(tableDump['attachments']!, 'local_path', 'attachments');
    rewriteRowPath(tableDump['entry_items']!, 'photo_path', 'attachments');
    rewriteRowPath(tableDump['people']!, 'photo_path', 'people_photos');
    rewriteRowPath(tableDump['event_attachments']!, 'file_path', 'event_attachments');

    // Rewrite family_profile_data.photo_path inside app_settings if present
    for (final setting in tableDump['app_settings']!) {
      if (setting['key'] == 'family_profile_data' && setting['value'] is String) {
        try {
          final decoded = jsonDecode(setting['value'] as String);
          if (decoded is Map<String, dynamic>) {
            final photo = decoded['photo_path'] as String?;
            final rewritten = registerImage(photo, 'family_profile');
            if (rewritten != null) {
              decoded['photo_path'] = rewritten;
              setting['value'] = jsonEncode(decoded);
            }
          }
        } catch (_) {}
      }
    }

    final peopleCount = tableDump['people']!.length;
    final eventsCount = tableDump['events']!.length;
    final entriesCount = tableDump['entries']!.length;
    final itemsCount = tableDump['entry_items']!.length;
    final imagesCount = archiveImageSources.length;

    final metadata = BackupMetadata(
      backupVersion: 5,
      appVersion: '1.0.14',
      createdAt: now,
      isEncrypted: isEncrypted,
      peopleCount: peopleCount,
      eventsCount: eventsCount,
      entriesCount: entriesCount,
      itemsCount: itemsCount,
      imagesCount: imagesCount,
    );

    final archive = Archive();
    final manifestBytes = utf8.encode(jsonEncode(metadata.toJson()));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    final payloadJsonBytes = utf8.encode(jsonEncode(tableDump));

    if (isEncrypted) {
      final saltBytes = _generateRandomBytes(16);
      final secretKey = await _deriveAesKey(
        trimmedPassword,
        saltBytes,
        iterations: _pbkdf2Iterations,
      );
      final aesGcm = AesGcm.with256bits();

      // Encrypt data.json into data.enc.json
      final dataNonce = _generateRandomBytes(12);
      final dataBox = await aesGcm.encrypt(
        payloadJsonBytes,
        secretKey: secretKey,
        nonce: dataNonce,
      );
      final encryptedEnvelope = {
        'vyavahaar_backup_version': 5,
        'is_encrypted': true,
        'kdf': {
          'algorithm': 'PBKDF2-HMAC-SHA256',
          'iterations': _pbkdf2Iterations,
          'salt': base64Encode(saltBytes),
        },
        'cipher': {
          'algorithm': 'AES-256-GCM',
          'nonce': base64Encode(dataNonce),
          'tag': base64Encode(dataBox.mac.bytes),
          'ciphertext': base64Encode(dataBox.cipherText),
        },
      };
      final encDataBytes = utf8.encode(jsonEncode(encryptedEnvelope));
      archive.addFile(ArchiveFile('data.enc.json', encDataBytes.length, encDataBytes));

      // Encrypt every image binary using the same derived key (fast, 12B nonce + 16B mac + cipherText)
      for (final entry in archiveImageSources.entries) {
        final rawImgBytes = await entry.value.readAsBytes();
        final imgNonce = _generateRandomBytes(12);
        final imgBox = await aesGcm.encrypt(
          rawImgBytes,
          secretKey: secretKey,
          nonce: imgNonce,
        );
        final packed = BytesBuilder(copy: false)
          ..add(imgNonce)
          ..add(imgBox.mac.bytes)
          ..add(imgBox.cipherText);
        final encImgBytes = packed.toBytes();
        final zipPath = 'images/${entry.key}.enc';
        archive.addFile(ArchiveFile(zipPath, encImgBytes.length, encImgBytes));
      }
    } else {
      archive.addFile(ArchiveFile('data.json', payloadJsonBytes.length, payloadJsonBytes));
      for (final entry in archiveImageSources.entries) {
        final rawImgBytes = await entry.value.readAsBytes();
        final zipPath = 'images/${entry.key}';
        archive.addFile(ArchiveFile(zipPath, rawImgBytes.length, rawImgBytes));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    final backupDir = Directory(p.join(baseDir.path, 'backups'));
    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
    }

    final filename = 'vyavahaar_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
    final outFile = File(p.join(backupDir.path, filename));
    await outFile.writeAsBytes(zipBytes, flush: true);

    return BackupCreateResult(
      file: outFile,
      metadata: metadata,
      fileSizeBytes: zipBytes.length,
    );
  }

  /// Inspects a .zip or legacy .json backup file before restoring.
  Future<BackupInspection> inspectBackup(File backupFile) async {
    final rawBytes = await backupFile.readAsBytes();
    if (_looksLikeZip(rawBytes)) {
      final archive = ZipDecoder().decodeBytes(rawBytes);
      final manifestFile = _findArchiveFile(archive, 'manifest.json');
      if (manifestFile != null) {
        final jsonMap = jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
        return BackupInspection(
          isZip: true,
          isEncrypted: jsonMap['is_encrypted'] as bool? ?? false,
          backupVersion: jsonMap['vyavahaar_backup_version'] as int? ?? 5,
          createdAt: jsonMap['created_at'] as String?,
          peopleCount: jsonMap['people_count'] as int? ?? 0,
          eventsCount: jsonMap['events_count'] as int? ?? 0,
          entriesCount: jsonMap['entries_count'] as int? ?? 0,
          itemsCount: jsonMap['items_count'] as int? ?? 0,
          imagesCount: jsonMap['images_count'] as int? ?? 0,
        );
      }

      final hasEnc = _findArchiveFile(archive, 'data.enc.json') != null;
      final imgCount = archive.where((f) => f.isFile && f.name.startsWith('images/')).length;
      return BackupInspection(
        isZip: true,
        isEncrypted: hasEnc,
        backupVersion: 5,
        imagesCount: imgCount,
      );
    }

    // Legacy JSON inspection
    final envelope = jsonDecode(utf8.decode(rawBytes)) as Map<String, dynamic>;
    final meta = envelope['metadata'] as Map<String, dynamic>?;
    return BackupInspection(
      isZip: false,
      isEncrypted: envelope['is_encrypted'] as bool? ?? false,
      backupVersion: envelope['vyavahaar_backup_version'] as int? ?? 4,
      createdAt: envelope['created_at'] as String?,
      peopleCount: meta?['people_count'] as int? ?? 0,
      eventsCount: meta?['events_count'] as int? ?? 0,
      entriesCount: meta?['entries_count'] as int? ?? 0,
      itemsCount: meta?['items_count'] as int? ?? 0,
      imagesCount: 0,
    );
  }

  /// Restores database + all images from a .zip or legacy .json backup atomically in one shot.
  Future<BackupRestoreResult> restoreBackup(
    File backupFile, {
    String? password,
    Directory? overrideBaseDir,
  }) async {
    await SchemaMigrations.ensureAllTablesAndColumns(_db);
    final baseDir = overrideBaseDir ?? await getApplicationDocumentsDirectory();
    final rawBytes = await backupFile.readAsBytes();

    Map<String, dynamic> payloadMap;
    int imagesRestored = 0;

    if (_looksLikeZip(rawBytes)) {
      final archive = ZipDecoder().decodeBytes(rawBytes);
      final encDataFile = _findArchiveFile(archive, 'data.enc.json');
      final plainDataFile = _findArchiveFile(archive, 'data.json');

      SecretKey? sharedKey;

      if (encDataFile != null) {
        final trimmedPwd = password?.trim() ?? '';
        if (trimmedPwd.isEmpty) {
          throw ArgumentError('Password required for encrypted backup');
        }
        final envelope = jsonDecode(utf8.decode(encDataFile.content as List<int>))
            as Map<String, dynamic>;
        final kdfData = envelope['kdf'] as Map<String, dynamic>?;
        final cipherData = envelope['cipher'] as Map<String, dynamic>?;
        if (kdfData == null || cipherData == null) {
          throw const FormatException('Invalid or corrupt encrypted backup envelope');
        }

        final saltBytes = base64Decode(kdfData['salt'] as String);
        final iterations = kdfData['iterations'] as int? ?? _pbkdf2Iterations;
        sharedKey = await _deriveAesKey(trimmedPwd, saltBytes, iterations: iterations);

        final nonceBytes = base64Decode(cipherData['nonce'] as String);
        final tagBytes = base64Decode(cipherData['tag'] as String);
        final cipherText = base64Decode(cipherData['ciphertext'] as String);

        try {
          final decryptedBytes = await AesGcm.with256bits().decrypt(
            SecretBox(cipherText, nonce: nonceBytes, mac: Mac(tagBytes)),
            secretKey: sharedKey,
          );
          payloadMap = jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;
        } catch (_) {
          throw ArgumentError('Incorrect password or corrupted backup file');
        }
      } else if (plainDataFile != null) {
        payloadMap = jsonDecode(utf8.decode(plainDataFile.content as List<int>))
            as Map<String, dynamic>;
      } else {
        throw const FormatException('ZIP backup does not contain data.json or data.enc.json');
      }

      // Extract & restore all images from ZIP into current app documents directory
      final aesGcm = AesGcm.with256bits();
      for (final archFile in archive) {
        if (!archFile.isFile || !archFile.name.startsWith('images/')) continue;

        final fileBytes = archFile.content as List<int>;
        String relInsideImages = archFile.name.substring('images/'.length);
        List<int> outBytes = fileBytes;

        if (relInsideImages.endsWith('.enc') && sharedKey != null) {
          relInsideImages = relInsideImages.substring(0, relInsideImages.length - 4);
          if (fileBytes.length < 28) continue;
          final nonce = fileBytes.sublist(0, 12);
          final mac = fileBytes.sublist(12, 28);
          final cipher = fileBytes.sublist(28);
          try {
            outBytes = await aesGcm.decrypt(
              SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
              secretKey: sharedKey,
            );
          } catch (_) {
            continue;
          }
        }

        final destPath = p.joinAll([baseDir.path, ...relInsideImages.split('/')]);
        final destFile = File(destPath);
        if (!destFile.parent.existsSync()) {
          await destFile.parent.create(recursive: true);
        }
        await destFile.writeAsBytes(outBytes, flush: true);
        imagesRestored++;
      }

      // Remap zip_asset:<relPath> pointers inside payload back to live absolute paths
      _remapExtractedImagePaths(payloadMap, baseDir);
    } else {
      // Legacy JSON / Encrypted JSON backup restore
      final envelope = jsonDecode(utf8.decode(rawBytes)) as Map<String, dynamic>;
      final isEncrypted = envelope['is_encrypted'] as bool? ?? false;

      if (isEncrypted) {
        final trimmedPwd = password?.trim() ?? '';
        if (trimmedPwd.isEmpty) {
          throw ArgumentError('Password required for encrypted backup');
        }

        final cipherData = envelope['cipher'] as Map<String, dynamic>?;
        final kdfData = envelope['kdf'] as Map<String, dynamic>?;
        if (cipherData == null || kdfData == null) {
          throw const FormatException('Invalid or corrupt encrypted backup envelope');
        }

        final saltBytes = base64Decode(kdfData['salt'] as String);
        final nonceBytes = base64Decode(cipherData['nonce'] as String);
        final tagBytes = base64Decode(cipherData['tag'] as String);
        final cipherTextBytes = base64Decode(cipherData['ciphertext'] as String);
        final iterations = kdfData['iterations'] as int? ?? _pbkdf2Iterations;

        final secretKey = await _deriveAesKey(trimmedPwd, saltBytes, iterations: iterations);
        try {
          final decryptedBytes = await AesGcm.with256bits().decrypt(
            SecretBox(cipherTextBytes, nonce: nonceBytes, mac: Mac(tagBytes)),
            secretKey: secretKey,
          );
          payloadMap = jsonDecode(utf8.decode(decryptedBytes)) as Map<String, dynamic>;
        } catch (_) {
          throw ArgumentError('Incorrect password or corrupted backup file');
        }
      } else {
        payloadMap = envelope['payload'] as Map<String, dynamic>? ?? {};
      }
    }

    // Normalize legacy keys (v3/v4 camelCase support) before restoring
    _normalizeLegacyPayloadAliases(payloadMap);

    // Inspect target table columns before entering transaction
    final Map<String, Set<String>> targetColumnsByTable = {};
    for (final table in _restoreTableOrder) {
      targetColumnsByTable[table] = await _getTableColumns(table);
    }

    int peopleCount = 0;
    int eventsCount = 0;
    int entriesCount = 0;
    int itemsCount = 0;

    // Atomic SQLite transaction: delete children -> parents, then insert parents -> children
    await _db.transaction(() async {
      for (final table in _restoreTableOrder.reversed) {
        try {
          await _db.customStatement('DELETE FROM $table;');
        } catch (_) {}
      }

      for (final table in _restoreTableOrder) {
        final validCols = targetColumnsByTable[table] ?? const {};
        if (validCols.isEmpty) continue;

        final rawRows = (payloadMap[table] as List<dynamic>?) ?? const [];
        for (final rawItem in rawRows) {
          if (rawItem is! Map) continue;
          final row = Map<String, dynamic>.from(rawItem);
          _sanitizeRowValuesForTable(table, row);

          final insertCols = <String>[];
          final variables = <Variable<Object>>[];

          for (final entry in row.entries) {
            if (!validCols.contains(entry.key)) continue;
            insertCols.add(entry.key);
            variables.add(_toDriftVariable(entry.value));
          }

          if (insertCols.isEmpty) continue;

          final colsSql = insertCols.join(', ');
          final placeholders = List.filled(insertCols.length, '?').join(', ');
          await _db.customInsert(
            'INSERT OR REPLACE INTO $table ($colsSql) VALUES ($placeholders)',
            variables: variables,
          );

          if (table == 'people') peopleCount++;
          if (table == 'events') eventsCount++;
          if (table == 'entries') entriesCount++;
          if (table == 'entry_items') itemsCount++;
        }
      }

      await _db.customStatement('PRAGMA foreign_key_check;');
    });

    return BackupRestoreResult(
      peopleRestored: peopleCount,
      eventsRestored: eventsCount,
      entriesRestored: entriesCount,
      itemsRestored: itemsCount,
      imagesRestored: imagesRestored,
    );
  }

  /// Share backup file via native share sheet
  static Future<void> shareBackup(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Vyavahaar Backup (.zip)');
  }

  Future<List<Map<String, dynamic>>> _safeSelectTable(String table) async {
    try {
      final rows = await _db.customSelect('SELECT * FROM $table;').get();
      return rows.map((r) {
        final map = <String, dynamic>{};
        for (final entry in r.data.entries) {
          final v = entry.value;
          map[entry.key] = v is BigInt ? v.toInt() : v;
        }
        return map;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Set<String>> _getTableColumns(String table) async {
    try {
      final rows = await _db.customSelect('PRAGMA table_info($table);').get();
      return rows
          .map((r) => r.readNullable<String>('name'))
          .whereType<String>()
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  File? _resolveExistingImageFile(
    String rawPath,
    Directory baseDir,
    String defaultSubdir,
  ) {
    final direct = File(rawPath);
    if (direct.existsSync()) return direct;

    final fallback = File(p.join(baseDir.path, defaultSubdir, p.basename(rawPath)));
    if (fallback.existsSync()) return fallback;

    return null;
  }

  void _remapExtractedImagePaths(Map<String, dynamic> payloadMap, Directory baseDir) {
    String? remapValue(dynamic rawVal, String fallbackSubdir) {
      if (rawVal is! String || rawVal.isEmpty) return null;
      if (rawVal.startsWith(_zipAssetPrefix)) {
        final rel = rawVal.substring(_zipAssetPrefix.length);
        return p.joinAll([baseDir.path, ...rel.split('/')]);
      }
      // Fallback: if old path basename exists in extracted subdir
      final candidate = File(p.join(baseDir.path, fallbackSubdir, p.basename(rawVal)));
      if (candidate.existsSync()) return candidate.path;
      return rawVal;
    }

    void remapTableColumn(String table, String column, String subdir) {
      final rows = payloadMap[table];
      if (rows is! List) return;
      for (final item in rows) {
        if (item is Map) {
          final remapped = remapValue(item[column], subdir);
          if (remapped != null) item[column] = remapped;
        }
      }
    }

    remapTableColumn('attachments', 'local_path', 'attachments');
    remapTableColumn('entry_items', 'photo_path', 'attachments');
    remapTableColumn('people', 'photo_path', 'people_photos');
    remapTableColumn('event_attachments', 'file_path', 'event_attachments');

    final settingsRows = payloadMap['app_settings'];
    if (settingsRows is List) {
      for (final item in settingsRows) {
        if (item is Map && item['key'] == 'family_profile_data' && item['value'] is String) {
          try {
            final decoded = jsonDecode(item['value'] as String);
            if (decoded is Map<String, dynamic>) {
              final remapped = remapValue(decoded['photo_path'], 'family_profile');
              if (remapped != null) {
                decoded['photo_path'] = remapped;
                item['value'] = jsonEncode(decoded);
              }
            }
          } catch (_) {}
        }
      }
    }
  }

  void _normalizeLegacyPayloadAliases(Map<String, dynamic> payloadMap) {
    if (!payloadMap.containsKey('entry_items') && payloadMap.containsKey('items')) {
      payloadMap['entry_items'] = payloadMap['items'];
    }

    void aliasRow(List<dynamic>? rows, Map<String, String> camelToSnake) {
      if (rows == null) return;
      for (final item in rows) {
        if (item is Map) {
          for (final pair in camelToSnake.entries) {
            if (!item.containsKey(pair.value) && item.containsKey(pair.key)) {
              item[pair.value] = item[pair.key];
            }
          }
        }
      }
    }

    aliasRow(payloadMap['people'] as List<dynamic>?, const {
      'familyId': 'family_id',
      'name': 'full_name',
      'phone': 'phone_number',
      'relationship': 'relationship_label',
      'village': 'address',
      'photoPath': 'photo_path',
    });

    aliasRow(payloadMap['events'] as List<dynamic>?, const {
      'eventType': 'event_type',
      'eventDate': 'event_date',
      'endDate': 'end_date',
      'startTime': 'start_time',
      'endTime': 'end_time',
      'villageCity': 'village_city',
      'eventScope': 'event_scope',
      'hostPersonId': 'host_person_id',
      'hostPersonName': 'host_person_name',
    });

    aliasRow(payloadMap['entries'] as List<dynamic>?, const {
      'personId': 'person_id',
      'eventId': 'event_id',
      'transactionType': 'transaction_type',
      'cashAmountPaise': 'amount_paise',
      'transactionDate': 'transaction_date',
      'recordedAt': 'recorded_at',
      'cancelledAt': 'cancelled_at',
      'deleted_at': 'archived_at',
    });

    aliasRow(payloadMap['entry_items'] as List<dynamic>?, const {
      'entryId': 'entry_id',
      'itemName': 'item_name',
      'estimatedValuePaise': 'estimated_value_paise',
      'condition': 'notes',
      'photoPath': 'photo_path',
    });

    aliasRow(payloadMap['reminders'] as List<dynamic>?, const {
      'entryId': 'entry_id',
      'reminderDate': 'reminder_date',
      'isCompleted': 'is_completed',
    });
  }

  void _sanitizeRowValuesForTable(String table, Map<String, dynamic> row) {
    // Empty archived_at must be strictly NULL so active queries show restored rows
    if (row['archived_at'] == '') row['archived_at'] = null;

    // Optional FK columns: empty string '' would fail PRAGMA foreign_keys
    const nullableFkCols = [
      'family_id',
      'event_id',
      'entry_id',
      'person_id',
      'function_id',
      'host_person_id',
    ];
    for (final col in nullableFkCols) {
      if (row[col] == '') row[col] = null;
    }

    // Boolean to SQLite int coercion (e.g. reminders.is_completed / events.is_all_day)
    for (final key in row.keys.toList()) {
      final v = row[key];
      if (v is bool) {
        row[key] = v ? 1 : 0;
      }
    }
  }

  Variable<Object> _toDriftVariable(dynamic val) {
    if (val == null) return const Variable<Object>(null);
    if (val is int) return Variable<int>(val);
    if (val is BigInt) return Variable<int>(val.toInt());
    if (val is double) return Variable<double>(val);
    if (val is bool) return Variable<int>(val ? 1 : 0);
    return Variable<String>(val.toString());
  }

  ArchiveFile? _findArchiveFile(Archive archive, String name) {
    for (final f in archive) {
      if (f.isFile && f.name == name) return f;
    }
    return null;
  }

  bool _looksLikeZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B;
  }

  Future<SecretKey> _deriveAesKey(
    String password,
    List<int> saltBytes, {
    required int iterations,
  }) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: saltBytes,
    );
  }

  List<int> _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
