import '../database/app_database.dart';

abstract class SettingsRepository {
  Future<String?> getSetting(String key);
  Stream<String?> watchSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<Map<String, String>> getAllSettings();
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
}
