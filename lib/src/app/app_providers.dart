import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import '../data/database/app_database.dart';
import '../data/database/database_module.dart';
import '../data/repositories/entries_repository.dart';
import '../data/repositories/people_repository.dart';
import '../data/repositories/events_repository.dart';
import '../data/repositories/families_repository.dart';
import '../data/repositories/settings_repository.dart';
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

/// Dashboard summary async provider
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final repo = ref.watch(entriesRepositoryProvider);
  return repo.getDashboardSummary();
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

/// Event detail future provider by ID
final eventDetailProvider = FutureProvider.family<Event?, String>((ref, id) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getEventById(id);
});

/// Active families stream provider
final activeFamiliesListProvider = StreamProvider<List<Family>>((ref) {
  final repo = ref.watch(familiesRepositoryProvider);
  return repo.watchActiveFamilies();
});

/// Person transaction history statistics provider (received_paise, given_paise)
final personHistoryStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, personId) async {
  final repo = ref.watch(entriesRepositoryProvider);
  return repo.getPersonHistoryStats(personId);
});
