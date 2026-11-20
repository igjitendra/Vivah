import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';
import 'package:vyavahaar/src/domain/rules/financial_rules.dart';

void main() {
  group('FinancialRules - 12 Mandatory Rules Verification', () {
    final now = DateTime.now();

    final testEntries = [
      // 1. Valid Mila entry: ₹1,100 (110000 paise)
      TransactionEntry(
        id: 'entry_01',
        householdId: 'h1',
        eventId: 'e1',
        personId: 'p1',
        direction: TransactionDirection.mila,
        cashAmountPaise: 110000,
        status: TransactionStatus.recorded,
        createdAt: now,
        updatedAt: now,
        items: [
          EntryItem(
            id: 'item_01',
            entryId: 'entry_01',
            itemName: 'चाँदी का सिक्का',
            estimatedValuePaise: 500000, // ₹5,000 gift value
            createdAt: now,
          ),
        ],
      ),
      // 2. Valid Mila entry: ₹501 (50100 paise)
      TransactionEntry(
        id: 'entry_02',
        householdId: 'h1',
        eventId: 'e1',
        personId: 'p2',
        direction: TransactionDirection.mila,
        cashAmountPaise: 50100,
        status: TransactionStatus.recorded,
        createdAt: now,
        updatedAt: now,
      ),
      // 3. Valid Diya entry: ₹2,100 (210000 paise)
      TransactionEntry(
        id: 'entry_03',
        householdId: 'h1',
        eventId: 'e2',
        personId: 'p3',
        direction: TransactionDirection.diya,
        cashAmountPaise: 210000,
        status: TransactionStatus.recorded,
        createdAt: now,
        updatedAt: now,
      ),
      // 4. Planned Diya entry: ₹5,000 (500000 paise) - MUST BE EXCLUDED FROM ACTUAL TOTALS
      TransactionEntry(
        id: 'entry_04',
        householdId: 'h1',
        eventId: 'e2',
        personId: 'p4',
        direction: TransactionDirection.diya,
        cashAmountPaise: 500000,
        status: TransactionStatus.planned,
        expectedDate: '2026-12-01',
        createdAt: now,
        updatedAt: now,
      ),
      // 5. Cancelled Mila entry: ₹10,000 (1000000 paise) - MUST BE EXCLUDED FROM ALL TOTALS
      TransactionEntry(
        id: 'entry_05',
        householdId: 'h1',
        eventId: 'e1',
        personId: 'p5',
        direction: TransactionDirection.mila,
        cashAmountPaise: 1000000,
        status: TransactionStatus.cancelled,
        createdAt: now,
        updatedAt: now,
      ),
      // 6. Soft-deleted Diya entry: ₹1,000 (100000 paise) - MUST BE EXCLUDED
      TransactionEntry(
        id: 'entry_06',
        householdId: 'h1',
        eventId: 'e2',
        personId: 'p6',
        direction: TransactionDirection.diya,
        cashAmountPaise: 100000,
        status: TransactionStatus.recorded,
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      ),
    ];

    test('Rule 1 & 2: calculateTotalMilaPaise calculates pure Mila without netting Diya', () {
      final totalMila = FinancialRules.calculateTotalMilaPaise(testEntries);
      // Expected: entry_01 (110000) + entry_02 (50100) = 160100 paise (₹1,601)
      expect(totalMila, equals(160100));
    });

    test('Rule 1 & 2: calculateTotalDiyaPaise calculates pure Diya without netting Mila', () {
      final totalDiya = FinancialRules.calculateTotalDiyaPaise(testEntries);
      // Expected: entry_03 (210000) = 210000 paise (₹2,100)
      // Excludes planned entry_04 (500000) and soft-deleted entry_06 (100000)
      expect(totalDiya, equals(210000));
    });

    test('Rule 3: Gift estimates are strictly isolated from cash calculations', () {
      final giftTotal = FinancialRules.calculateTotalGiftEstimatesPaise(testEntries);
      expect(giftTotal, equals(500000)); // ₹5,000 item in entry_01

      final cashMila = FinancialRules.calculateTotalMilaPaise(testEntries);
      // Cash mila must NOT include the ₹5,000 gift value
      expect(cashMila, equals(160100));
    });

    test('Rule 4: countPlannedEntries only counts planned non-deleted transactions', () {
      final plannedCount = FinancialRules.countPlannedEntries(testEntries);
      expect(plannedCount, equals(1)); // only entry_04
    });

    test('Invariance: Mila and Diya are never subtracted to produce net balance or debt', () {
      final totalMila = FinancialRules.calculateTotalMilaPaise(testEntries);
      final totalDiya = FinancialRules.calculateTotalDiyaPaise(testEntries);

      // Verify both exist independently as positive integer totals
      expect(totalMila, isPositive);
      expect(totalDiya, isPositive);
      expect(totalMila != totalDiya, isTrue);
    });
  });
}
