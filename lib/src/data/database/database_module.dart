import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'daos/families_dao.dart';
import 'daos/people_dao.dart';
import 'daos/events_dao.dart';
import 'daos/entries_dao.dart';
import 'daos/entry_items_dao.dart';
import 'daos/reminders_dao.dart';
import 'daos/settings_dao.dart';

/// Database provider providing the singleton AppDatabase
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Individual DAO providers
final familiesDaoProvider = Provider<FamiliesDao>((ref) {
  return ref.watch(appDatabaseProvider).familiesDao;
});

final peopleDaoProvider = Provider<PeopleDao>((ref) {
  return ref.watch(appDatabaseProvider).peopleDao;
});

final eventsDaoProvider = Provider<EventsDao>((ref) {
  return ref.watch(appDatabaseProvider).eventsDao;
});

final entriesDaoProvider = Provider<EntriesDao>((ref) {
  return ref.watch(appDatabaseProvider).entriesDao;
});

final entryItemsDaoProvider = Provider<EntryItemsDao>((ref) {
  return ref.watch(appDatabaseProvider).entryItemsDao;
});

final remindersDaoProvider = Provider<RemindersDao>((ref) {
  return ref.watch(appDatabaseProvider).remindersDao;
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
});
