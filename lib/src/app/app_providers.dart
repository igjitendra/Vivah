import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../data/database/app_database.dart';
import '../data/database/database_module.dart';
import '../data/database/tables/attachments_table.dart';
import '../data/repositories/entries_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/events_repository.dart';
import '../data/repositories/families_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../features/family_profile/data/family_profile_repository.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/transaction_enums.dart';

/// Database provider alias
final databaseProvider = appDatabaseProvider;

/// Repository providers
final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftEntriesRepository(db);
});

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftPeopleRepository(db);
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftEventsRepository(db);
});

final familiesRepositoryProvider = Provider<FamiliesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFamiliesRepository(db);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSettingsRepository(db);
});

/// Reactive live stream of user-created custom event types
final customEventTypesProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchCustomEventTypes();
});

/// Dashboard summary reactive stream provider (100% live updates on every entry/event/person change)
final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  final repo = ref.watch(entriesRepositoryProvider);
  return repo.watchDashboardSummary();
});

/// Filtered entries stream provider
final entriesListProvider = StreamProvider.family<List<TransactionEntry>, TransactionDirection?>((ref, direction) {
  final repo = ref.watch(entriesRepositoryProvider);
  return repo.watchEntries(direction: direction);
});

/// Active people stream provider
final activePeopleListProvider = StreamProvider<List<Person>>((ref) {
  final repo = ref.watch(peopleRepositoryProvider);
  return repo.watchActivePeople();
});

/// Archived people stream provider
final archivedPeopleListProvider = StreamProvider<List<Person>>((ref) {
  final repo = ref.watch(peopleRepositoryProvider);
  return repo.watchArchivedPeople();
});

/// Active events stream provider
final activeEventsListProvider = StreamProvider<List<Event>>((ref) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.watchActiveEvents();
});

/// Archived events stream provider
final archivedEventsListProvider = StreamProvider<List<Event>>((ref) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.watchArchivedEvents();
});

/// Event detail reactive stream provider by ID (100% live financial & status updates)
final eventDetailProvider = StreamProvider.family<Event?, String>((ref, id) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.watchEventById(id);
});

/// Active families stream provider
final activeFamiliesListProvider = StreamProvider<List<Family>>((ref) {
  final repo = ref.watch(familiesRepositoryProvider);
  return repo.watchActiveFamilies();
});

/// Person transaction history statistics reactive stream provider (received_paise, given_paise)
final personHistoryStatsProvider = StreamProvider.family<Map<String, int>, String>((ref, personId) {
  final repo = ref.watch(entriesRepositoryProvider);
  return repo.watchPersonHistoryStats(personId);
});

/// Live Today Date Provider (Emits current date and auto-rolls over periodically)
final liveDateProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    yield DateTime.now();
  }
});

/// Family profile repository provider
final familyProfileRepositoryProvider = Provider<FamilyProfileRepository>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return DriftFamilyProfileRepository(settingsRepo);
});

/// Family profile reactive stream provider
final familyProfileProvider = StreamProvider<FamilyProfile>((ref) {
  final repo = ref.watch(familyProfileRepositoryProvider);
  return repo.watchFamilyProfile();
});

/// Provider for entry proof image (watches a single entry's proof attachment)
final entryProofProvider =
    StreamProvider.family<AttachmentRow?, String>((ref, entryId) {
  final db = ref.watch(appDatabaseProvider);
  return db.attachmentsDao.watchProofForEntry(entryId);
});

