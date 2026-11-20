import '../entities/entities.dart';

/// Pure domain implementation of the 12 mandatory financial & transaction rules
class FinancialRules {
  FinancialRules._();

  /// Calculates total Mila (Received) cash in integer paise.
  /// Strict Rule 1: Mila and Diya are never netted or combined.
  /// Strict Rule 3: Gift estimates are excluded.
  /// Strict Rule 4: Planned and cancelled entries are excluded.
  static int calculateTotalMilaPaise(List<TransactionEntry> entries) {
    return entries
        .where((e) =>
            e.direction.value == 'mila' &&
            e.status.value == 'recorded' &&
            e.deletedAt == null)
        .fold(0, (sum, e) => sum + e.cashAmountPaise);
  }

  /// Calculates total Diya (Given) cash in integer paise.
  /// Strict Rule 1: Mila and Diya are never netted.
  /// Strict Rule 4: Planned and cancelled entries are excluded.
  static int calculateTotalDiyaPaise(List<TransactionEntry> entries) {
    return entries
        .where((e) =>
            e.direction.value == 'diya' &&
            e.status.value == 'recorded' &&
            e.deletedAt == null)
        .fold(0, (sum, e) => sum + e.cashAmountPaise);
  }

  /// Calculates total physical gift estimated value in integer paise.
  /// Strictly kept separate from cash amounts!
  static int calculateTotalGiftEstimatesPaise(List<TransactionEntry> entries) {
    int total = 0;
    for (final e in entries) {
      if (e.status.value == 'recorded' && e.deletedAt == null) {
        for (final item in e.items) {
          total += item.estimatedValuePaise ?? 0;
        }
      }
    }
    return total;
  }

  /// Counts planned entries for budgeting
  static int countPlannedEntries(List<TransactionEntry> entries) {
    return entries
        .where((e) => e.status.value == 'planned' && e.deletedAt == null)
        .length;
  }
}
