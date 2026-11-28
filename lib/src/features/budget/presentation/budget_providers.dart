import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../data/budget_repository.dart';
import '../domain/budget_models.dart';

/// Repository provider for Event Budgets, Vendor Payments & Returnable Arrangements.
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final eventsRepo = ref.watch(eventsRepositoryProvider);
  return DriftBudgetRepository(db, eventsRepo);
});

/// Live reactive stream of all Event Budget categories, itemized expenses,
/// installment payments, and returnable temporary funds.
final budgetDashboardProvider = StreamProvider<BudgetDashboardSnapshot>((ref) {
  return ref.watch(budgetRepositoryProvider).watchDashboardSnapshot();
});
