import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repositories/entries_repository.dart';
import '../domain/entities/entities.dart';
import '../domain/enums/transaction_enums.dart';

/// Database instance provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Active household ID provider (default: household_primary_01)
final activeHouseholdIdProvider = StateProvider<String>((ref) => 'household_primary_01');

/// Entries repository provider
final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftEntriesRepository(db);
});

/// Dashboard summary async provider
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final repo = ref.watch(entriesRepositoryProvider);
  final householdId = ref.watch(activeHouseholdIdProvider);
  return repo.getDashboardSummary(householdId: householdId);
});

/// Filtered entries stream provider
final entriesListProvider = StreamProvider.family<List<TransactionEntry>, TransactionDirection?>((ref, direction) {
  final repo = ref.watch(entriesRepositoryProvider);
  final householdId = ref.watch(activeHouseholdIdProvider);
  return repo.watchEntries(direction: direction, householdId: householdId);
});
