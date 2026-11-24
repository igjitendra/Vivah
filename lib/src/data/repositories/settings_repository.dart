import 'dart:convert';
import '../database/app_database.dart';

abstract class SettingsRepository {
  Future<String?> getSetting(String key);
  Stream<String?> watchSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<Map<String, String>> getAllSettings();

  // Custom Event Types
  Future<List<String>> getCustomEventTypes();
  Stream<List<String>> watchCustomEventTypes();
  Future<void> addCustomEventType(String newType);
  Future<void> removeCustomEventType(String typeToDelete);
}

class DriftSettingsRepository implements SettingsRepository {
  final AppDatabase _db;

  DriftSettingsRepository(this._db);

  @override
  Future<String?> getSetting(String key) {
    return _db.settingsDao.getSetting(key);
  }

  @override
  Stream<String?> watchSetting(String key) {
    return _db.settingsDao.watchSetting(key);
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _db.settingsDao.setSetting(key, value);
  }

  @override
  Future<Map<String, String>> getAllSettings() {
    return _db.settingsDao.getAllSettings();
  }

  @override
  Future<List<String>> getCustomEventTypes() async {
    final val = await getSetting('custom_event_types');
    final list = <String>[];
    if (val != null && val.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(val);
        if (decoded is List) {
          list.addAll(decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
        }
      } catch (_) {
        list.addAll(val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
    }
    return list;
  }

  @override
  Stream<List<String>> watchCustomEventTypes() {
    return watchSetting('custom_event_types').map((val) {
      if (val == null || val.trim().isEmpty) return <String>[];
      try {
        final decoded = jsonDecode(val);
        if (decoded is List) {
          return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        return val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return <String>[];
    });
  }

  @override
  Future<void> addCustomEventType(String newType) async {
    final clean = newType.trim();
    if (clean.isEmpty) return;
    final list = await getCustomEventTypes();
    if (!list.contains(clean)) {
      list.add(clean);
      await setSetting('custom_event_types', jsonEncode(list));
    }
  }

  @override
  Future<void> removeCustomEventType(String typeToDelete) async {
    final clean = typeToDelete.trim();
    final list = await getCustomEventTypes();
    if (list.remove(clean)) {
      await setSetting('custom_event_types', jsonEncode(list));
    }
  }
}
