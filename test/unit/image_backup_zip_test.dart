import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:vyavahaar/src/core/services/image_storage_service.dart';
import 'package:vyavahaar/src/data/database/app_database.dart';
import 'package:vyavahaar/src/data/repositories/entries_repository.dart';
import 'package:vyavahaar/src/data/repositories/events_repository.dart';
import 'package:vyavahaar/src/data/repositories/people_repository.dart';
import 'package:vyavahaar/src/data/repositories/settings_repository.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';
import 'package:vyavahaar/src/features/settings/services/backup_service.dart';

void _configureLinuxSqlite() {
  open.overrideFor(OperatingSystem.linux, () {
    for (final path in [
      '/usr/lib/aarch64-linux-gnu/libsqlite3.so.0',
      '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0',
      'libsqlite3.so.0',
      'libsqlite3.so',
    ]) {
      try {
        return DynamicLibrary.open(path);
      } catch (_) {}
    }
    return DynamicLibrary.open('libsqlite3.so');
  });
}

Uint8List _createPhotographicSampleJpg({int width = 2000, int height = 1500}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final r = (x * 13 + y * 7 + ((x ^ y) >> 1)) & 0xFF;
      final g = (y * 11 + ((x * 3) ^ y)) & 0xFF;
      final b = ((x * 5 + y * 17) ^ (x >> 2)) & 0xFF;
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 98));
}

Uint8List _createSamplePngBytes({int width = 1800, int height = 1400}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(210, 140, 70));
  img.fillRect(
    image,
    x1: 200,
    y1: 200,
    x2: width - 200,
    y2: height - 200,
    color: img.ColorRgb8(20, 100, 160),
  );
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  setUpAll(_configureLinuxSqlite);

  group('Image Compression & Gift Item Photo Persistence', () {
    test('compresses large camera photo down to <= 1280px JPEG', () async {
      final tempDir = await Directory.systemTemp.createTemp('vyavahaar_img_test_');
      addTearDown(() async => tempDir.delete(recursive: true));

      final rawPhoto = _createPhotographicSampleJpg(width: 2000, height: 1500);
      final saved = await ImageStorageService.compressAndSaveBytes(
        rawBytes: rawPhoto,
        subFolder: 'attachments',
        prefix: 'gift_test',
        maxDimension: 1280,
        quality: 75,
        overrideBaseDir: tempDir,
      );

      expect(saved.file.existsSync(), isTrue);
      expect(p.extension(saved.path), equals('.jpg'));
      expect(saved.compressedBytes, lessThan(saved.originalBytes));

      final decoded = img.decodeImage(await saved.file.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(1280));
      expect(decoded.height, lessThanOrEqualTo(1280));
    });

    test('persists and hydrates EntryItem.photoPath in SQLite schema v10', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final peopleRepo = DriftPeopleRepository(db);
      final entriesRepo = DriftEntriesRepository(db);
      final now = DateTime.now();

      await peopleRepo.createPerson(
        Person(
          id: 'p_gift_1',
          fullName: 'रमेश चाचा',
          relationshipLabel: 'चाचा',
          createdAt: now,
          updatedAt: now,
        ),
      );

      const expectedPhotoPath = '/data/mock/attachments/gift_ring.jpg';
      final entry = TransactionEntry(
        id: 'ent_gift_1',
        personId: 'p_gift_1',
        direction: TransactionDirection.received,
        transactionType: TransactionType.item,
        status: TransactionStatus.recorded,
        transactionDate: '2026-11-27',
        createdAt: now,
        updatedAt: now,
      );

      final items = [
        EntryItem(
          id: 'item_ring_1',
          entryId: 'ent_gift_1',
          itemName: 'सोने की अंगूठी',
          quantity: 1,
          unit: 'पीस',
          estimatedValuePaise: 2500000,
          photoPath: expectedPhotoPath,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await entriesRepo.saveEntryWithItemsAtomic(entry: entry, items: items);

      final loaded = await entriesRepo.getEntryById('ent_gift_1');
      expect(loaded, isNotNull);
      expect(loaded!.items.length, equals(1));
      expect(loaded.items.first.photoPath, equals(expectedPhotoPath));

      final watched = await entriesRepo.watchEntries().first;
      expect(watched.length, equals(1));
      expect(watched.first.items.first.photoPath, equals(expectedPhotoPath));
    });
  });

  group('Complete ZIP Backup & One-Shot Full Restore', () {
    test('packages all data + images into ZIP and restores everything in one shot', () async {
      final sourceDir = await Directory.systemTemp.createTemp('vyavahaar_src_');
      final restoreDir = await Directory.systemTemp.createTemp('vyavahaar_dst_');
      addTearDown(() async {
        await sourceDir.delete(recursive: true);
        await restoreDir.delete(recursive: true);
      });

      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final peopleRepo = DriftPeopleRepository(db);
      final eventsRepo = DriftEventsRepository(db);
      final entriesRepo = DriftEntriesRepository(db);
      final settingsRepo = DriftSettingsRepository(db);
      final backupService = BackupService(db);
      final now = DateTime.now();

      // Create compressed gift photo & proof photo & family avatar
      final giftImg = await ImageStorageService.compressAndSaveBytes(
        rawBytes: _createSamplePngBytes(width: 900, height: 700),
        subFolder: 'attachments',
        prefix: 'gift_item',
        overrideBaseDir: sourceDir,
      );
      final proofImg = await ImageStorageService.compressAndSaveBytes(
        rawBytes: _createSamplePngBytes(width: 800, height: 600),
        subFolder: 'attachments',
        prefix: 'proof_slip',
        overrideBaseDir: sourceDir,
      );
      final familyImg = await ImageStorageService.compressAndSaveBytes(
        rawBytes: _createSamplePngBytes(width: 600, height: 600),
        subFolder: 'family_profile',
        prefix: 'family_avatar',
        overrideBaseDir: sourceDir,
      );

      // Populate data
      await peopleRepo.createPerson(
        Person(
          id: 'p_zip_1',
          fullName: 'सुरेश मामा',
          relationshipLabel: 'मामा',
          village: 'रामपुर',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await eventsRepo.createEvent(
        Event(
          id: 'ev_zip_1',
          title: 'विवाह समारोह',
          eventType: EventType.shaadi,
          eventDate: '2026-12-10',
          functions: [
            EventFunction(
              id: 'fn_zip_1',
              eventId: 'ev_zip_1',
              title: 'हल्दी रस्म',
              functionDate: '2026-12-09',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );
      await entriesRepo.saveEntryWithItemsAtomic(
        entry: TransactionEntry(
          id: 'ent_zip_1',
          personId: 'p_zip_1',
          eventId: 'ev_zip_1',
          direction: TransactionDirection.received,
          transactionType: TransactionType.cashAndItem,
          status: TransactionStatus.recorded,
          amountPaise: 110000,
          transactionDate: '2026-12-10',
          createdAt: now,
          updatedAt: now,
        ),
        items: [
          EntryItem(
            id: 'it_zip_1',
            entryId: 'ent_zip_1',
            itemName: 'चाँदी का सिक्का',
            quantity: 1,
            unit: 'पीस',
            photoPath: giftImg.path,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      await db.attachmentsDao.setProof(
        id: 'att_zip_1',
        entryId: 'ent_zip_1',
        localPath: proofImg.path,
        note: 'शगुन लिफाफा',
      );
      await settingsRepo.setSetting(
        'family_profile_data',
        jsonEncode({
          'family_name': 'शर्मा परिवार',
          'photo_path': familyImg.path,
        }),
      );

      // 1. Create standard .zip backup
      final backupResult = await backupService.createZipBackup(
        overrideBaseDir: sourceDir,
      );
      expect(p.extension(backupResult.file.path), equals('.zip'));
      expect(backupResult.metadata.imagesCount, equals(3));

      // Verify ZIP archive contains manifest, data.json, and all 3 images
      final arch = ZipDecoder().decodeBytes(await backupResult.file.readAsBytes());
      final archNames = arch.where((f) => f.isFile).map((f) => f.name).toList();
      expect(archNames, contains('manifest.json'));
      expect(archNames, contains('data.json'));
      expect(archNames.where((n) => n.startsWith('images/')).length, equals(3));

      // Inspect ZIP before restore
      final inspection = await backupService.inspectBackup(backupResult.file);
      expect(inspection.isZip, isTrue);
      expect(inspection.isEncrypted, isFalse);
      expect(inspection.imagesCount, equals(3));
      expect(inspection.entriesCount, equals(1));

      // 2. Wipe database completely and restore into a brand new directory
      await db.customStatement('DELETE FROM attachments;');
      await db.customStatement('DELETE FROM entry_items;');
      await db.customStatement('DELETE FROM entries;');
      await db.customStatement('DELETE FROM event_functions;');
      await db.customStatement('DELETE FROM events;');
      await db.customStatement('DELETE FROM people;');
      await db.customStatement('DELETE FROM app_settings;');

      final restored = await backupService.restoreBackup(
        backupResult.file,
        overrideBaseDir: restoreDir,
      );

      expect(restored.peopleRestored, equals(1));
      expect(restored.eventsRestored, equals(1));
      expect(restored.entriesRestored, equals(1));
      expect(restored.itemsRestored, equals(1));
      expect(restored.imagesRestored, equals(3));

      // Verify DB + EventFunction + Gift Item Photo + Proof Photo + Family Photo are ALL restored under restoreDir
      final restoredEntry = await entriesRepo.getEntryById('ent_zip_1');
      expect(restoredEntry, isNotNull);
      expect(restoredEntry!.amountPaise, equals(110000));
      expect(restoredEntry.items.first.photoPath, isNotNull);
      expect(restoredEntry.items.first.photoPath!.startsWith(restoreDir.path), isTrue);
      expect(File(restoredEntry.items.first.photoPath!).existsSync(), isTrue);

      final restoredProof = await db.attachmentsDao.getProofForEntry('ent_zip_1');
      expect(restoredProof, isNotNull);
      expect(restoredProof!.localPath.startsWith(restoreDir.path), isTrue);
      expect(File(restoredProof.localPath).existsSync(), isTrue);

      final restoredEvent = await eventsRepo.getEventById('ev_zip_1');
      expect(restoredEvent, isNotNull);
      expect(restoredEvent!.functions.length, equals(1));

      final restoredPerson = await peopleRepo.getPersonById('p_zip_1');
      expect(restoredPerson?.village, equals('रामपुर'));

      final rawFam = await settingsRepo.getSetting('family_profile_data');
      final famJson = jsonDecode(rawFam!) as Map<String, dynamic>;
      expect((famJson['photo_path'] as String).startsWith(restoreDir.path), isTrue);
      expect(File(famJson['photo_path'] as String).existsSync(), isTrue);
    });

    test('supports password-encrypted ZIP backup and rejects wrong password', () async {
      final sourceDir = await Directory.systemTemp.createTemp('vyavahaar_enc_src_');
      final restoreDir = await Directory.systemTemp.createTemp('vyavahaar_enc_dst_');
      addTearDown(() async {
        await sourceDir.delete(recursive: true);
        await restoreDir.delete(recursive: true);
      });

      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final peopleRepo = DriftPeopleRepository(db);
      final entriesRepo = DriftEntriesRepository(db);
      final backupService = BackupService(db);
      final now = DateTime.now();

      final giftImg = await ImageStorageService.compressAndSaveBytes(
        rawBytes: _createSamplePngBytes(width: 600, height: 600),
        subFolder: 'attachments',
        prefix: 'enc_gift',
        overrideBaseDir: sourceDir,
      );

      await peopleRepo.createPerson(
        Person(
          id: 'p_enc_1',
          fullName: 'कपिल भाई',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await entriesRepo.saveEntryWithItemsAtomic(
        entry: TransactionEntry(
          id: 'ent_enc_1',
          personId: 'p_enc_1',
          direction: TransactionDirection.given,
          transactionType: TransactionType.item,
          transactionDate: '2026-11-27',
          createdAt: now,
          updatedAt: now,
        ),
        items: [
          EntryItem(
            id: 'it_enc_1',
            entryId: 'ent_enc_1',
            itemName: 'कलाई घड़ी',
            photoPath: giftImg.path,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final encZip = await backupService.createZipBackup(
        password: 'MyStrongPassword99',
        overrideBaseDir: sourceDir,
      );
      final inspection = await backupService.inspectBackup(encZip.file);
      expect(inspection.isZip, isTrue);
      expect(inspection.isEncrypted, isTrue);
      expect(inspection.imagesCount, equals(1));

      await expectLater(
        backupService.restoreBackup(
          encZip.file,
          password: 'WrongPassword',
          overrideBaseDir: restoreDir,
        ),
        throwsArgumentError,
      );

      final restored = await backupService.restoreBackup(
        encZip.file,
        password: 'MyStrongPassword99',
        overrideBaseDir: restoreDir,
      );
      expect(restored.entriesRestored, equals(1));
      expect(restored.imagesRestored, equals(1));

      final reloaded = await entriesRepo.getEntryById('ent_enc_1');
      expect(reloaded?.items.first.photoPath, isNotNull);
      expect(File(reloaded!.items.first.photoPath!).existsSync(), isTrue);
    });
  });
}
