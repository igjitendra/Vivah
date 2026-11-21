import '../entities/entities.dart';
import '../enums/transaction_enums.dart';

/// Pure domain implementation of the 12 mandatory financial & transaction rules
class FinancialRules {
  FinancialRules._();

  /// Calculates total Received (मिला) cash in integer paise.
  /// Strict Rule 1: Received and Given are never netted or combined.
  /// Strict Rule 3: Gift estimates are excluded.
  /// Strict Rule 4: Planned and cancelled entries are excluded.
  static int calculateTotalReceivedPaise(List<TransactionEntry> entries) {
    return entries
        .where((e) =>
            (e.direction == TransactionDirection.received || e.direction == TransactionDirection.mila) &&
            e.status == TransactionStatus.recorded &&
            e.archivedAt == null)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
  }

  /// Calculates total Given (दिया) cash in integer paise.
  /// Strict Rule 1: Received and Given are never netted.
  /// Strict Rule 4: Planned and cancelled entries are excluded.
  static int calculateTotalGivenPaise(List<TransactionEntry> entries) {
    return entries
        .where((e) =>
            (e.direction == TransactionDirection.given || e.direction == TransactionDirection.diya) &&
            e.status == TransactionStatus.recorded &&
            e.archivedAt == null)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
  }

  // Backward-compatibility aliases
  static int calculateTotalMilaPaise(List<TransactionEntry> entries) =>
      calculateTotalReceivedPaise(entries);

  static int calculateTotalDiyaPaise(List<TransactionEntry> entries) =>
      calculateTotalGivenPaise(entries);

  /// Calculates total physical gift estimated value in integer paise.
  /// Strictly kept separate from cash amounts!
  static int calculateTotalGiftEstimatesPaise(List<TransactionEntry> entries) {
    int total = 0;
    for (final e in entries) {
      if (e.status == TransactionStatus.recorded && e.archivedAt == null) {
        for (final item in e.items) {
          total += item.estimatedValuePaise ?? 0;
        }
      }
    }
    return total;
  }

  /// Counts planned entries for upcoming budgeting
  static int countPlannedEntries(List<TransactionEntry> entries) {
    return entries
        .where((e) => e.status == TransactionStatus.planned && e.archivedAt == null)
        .length;
  }

  /// Validates a transaction entry according to domain rules
  static void validateTransactionEntry({
    required TransactionType type,
    required TransactionDirection direction,
    required TransactionStatus status,
    required int? amountPaise,
    required List<EntryItem> items,
  }) {
    // 1. Validate cash type requires positive amount
    if (type == TransactionType.cash) {
      if (amountPaise == null || amountPaise <= 0) {
        throw ArgumentError('Cash transaction requires positive amount (amount > 0)');
      }
    }

    // 2. Validate item-only type requires at least one item
    if (type == TransactionType.item) {
      if (items.isEmpty) {
        throw ArgumentError('Item transaction requires at least one item');
      }
    }

    // 3. Validate cash and item requires both
    if (type == TransactionType.cashAndItem) {
      if (amountPaise == null || amountPaise <= 0) {
        throw ArgumentError('Cash and item transaction requires positive cash amount');
      }
      if (items.isEmpty) {
        throw ArgumentError('Cash and item transaction requires at least one item');
      }
    }

    // 4. Validate amount is not negative
    if (amountPaise != null && amountPaise < 0) {
      throw ArgumentError('Amount cannot be negative');
    }
  }
}
